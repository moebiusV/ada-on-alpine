pragma Ada_2022;

with Interfaces.C;
with System;

package body Imsg is

   use Interfaces.C;

   --  Little-endian 32-bit put/get (host byte order, matching imsg.c).
   procedure Put_U32 (B : in out Wire; Off : Positive; V : U32) is
   begin
      B (Off)     := Ada.Streams.Stream_Element (V          mod 256);
      B (Off + 1) := Ada.Streams.Stream_Element (V / 2 ** 8  mod 256);
      B (Off + 2) := Ada.Streams.Stream_Element (V / 2 ** 16 mod 256);
      B (Off + 3) := Ada.Streams.Stream_Element (V / 2 ** 24 mod 256);
   end Put_U32;

   function Get_U32 (B : Wire; Off : Positive) return U32 is
   begin
      return U32 (B (Off))     * 2 ** 0
           + U32 (B (Off + 1)) * 2 ** 8
           + U32 (B (Off + 2)) * 2 ** 16
           + U32 (B (Off + 3)) * 2 ** 24;
   end Get_U32;

   function Encode (F : Frame) return Wire is
      Result : Wire (1 .. Header_Size + F.Length);
   begin
      Put_U32 (Result, 1,  U32 (F.Kind));
      Put_U32 (Result, 5,  U32 (Header_Size + F.Length));
      Put_U32 (Result, 9,  U32 (F.Peer));
      Put_U32 (Result, 13, U32 (F.Pid));
      Result (Header_Size + 1 .. Result'Last) := F.Data;
      return Result;
   end Encode;

   function Decode (B : Wire) return Frame is
      Raw_Length : U32;
      Length     : Natural;
   begin
      if B'Length < Header_Size then
         raise Constraint_Error with "frame shorter than header";
      end if;
      Raw_Length := Get_U32 (B, 5) and not IMSG_FD_Mark;
      if Raw_Length < U32 (Header_Size)
        or else Raw_Length > U32 (Max_Msg_Size)
      then
         raise Constraint_Error with "frame length out of range";
      end if;
      Length := Natural (Raw_Length) - Header_Size;
      if B'Length /= Header_Size + Length then
         raise Constraint_Error with "frame length mismatch";
      end if;
      return Frame'
        (Length => Length,
         Kind   => Message_Type (Get_U32 (B, 1)),
         Peer   => Peer_Id (Get_U32 (B, 9)),
         Pid    => Pid_Type (Get_U32 (B, 13)),
         Data   => B (Header_Size + 1 .. B'Last));
   end Decode;

   subtype Bytes is Ada.Streams.Stream_Element_Array;

   --  Read exactly B'Length bytes into B, blocking across partial reads.
   procedure Read_Exact
     (Sock : GNAT.Sockets.Socket_Type; B : out Bytes) is
      use Ada.Streams;
      Pos  : Stream_Element_Offset := B'First;
      Last : Stream_Element_Offset;
   begin
      while Pos <= B'Last loop
         declare
            Rest : Bytes (1 .. B'Last - Pos + 1);
            N    : Stream_Element_Offset;
         begin
            GNAT.Sockets.Receive_Socket (Sock, Rest, Last);
            if Last < Rest'First then
               raise Transport_Error with "receive closed by peer";
            end if;
            N := Last - Rest'First + 1;
            B (Pos .. Pos + N - 1) := Rest (1 .. N);
            Pos := Pos + N;
         end;
      end loop;
   end Read_Exact;

   ---------------------------------------------------------------
   --  SCM_RIGHTS descriptor passing (OpenBSD imsg fd passing)  --
   ---------------------------------------------------------------

   --  struct iovec { void *iov_base; size_t iov_len; }
   type Iovec is record
      Iov_Base : System.Address;
      Iov_Len  : size_t;
   end record;
   pragma Convention (C, Iovec);

   --  struct cmsghdr { size_t cmsg_len; int cmsg_level; int cmsg_type; }
   type Cmsghdr is record
      Cmsg_Len   : size_t;
      Cmsg_Level : int;
      Cmsg_Type  : int;
   end record;
   pragma Convention (C, Cmsghdr);

   --  A cmsghdr immediately followed by one int (the SCM_RIGHTS data):
   --  20 bytes total (CMSG_LEN == CMSG_SPACE for a single int).
   type Cmsg_With_Fd is record
      Hdr : Cmsghdr;
      Fd  : int;
   end record;
   pragma Convention (C, Cmsg_With_Fd);

   --  struct msghdr { void *msg_name; socklen_t msg_namelen;
   --                  struct iovec *msg_iov; size_t msg_iovlen;
   --                  void *msg_control; size_t msg_controllen;
   --                  int msg_flags; }
   type Msghdr is record
      Msg_Name       : System.Address;
      Msg_Namelen    : unsigned;
      Msg_Iov        : System.Address;
      Msg_Iovlen     : size_t;
      Msg_Control    : System.Address;
      Msg_Controllen : size_t;
      Msg_Flags      : int;
   end record;
   pragma Convention (C, Msghdr);

   SOL_SOCKET       : constant := 1;
   SCM_RIGHTS       : constant := 1;
   MSG_CMSG_CLOEXEC : constant := 16#4000_0000#;

   Cmsg_Space : constant size_t := 20;   --  CMSG_SPACE(sizeof(int))

   function C_Sendmsg (S : int; Msg : access Msghdr; Flags : int)
     return long;
   pragma Import (C, C_Sendmsg, "sendmsg");

   function C_Recvmsg (S : int; Msg : access Msghdr; Flags : int)
     return long;
   pragma Import (C, C_Recvmsg, "recvmsg");

   --  Send B (Pos .. B'Last) to Sock, blocking across partial writes.
   procedure Send_All
     (Sock : GNAT.Sockets.Socket_Type;
      B    : Bytes;
      Pos  : Ada.Streams.Stream_Element_Offset)
   is
      use Ada.Streams;
      P    : Stream_Element_Offset := Pos;
      Last : Stream_Element_Offset;
   begin
      while P <= B'Last loop
         GNAT.Sockets.Send_Socket (Sock, B (P .. B'Last), Last);
         if Last < P then
            raise Transport_Error with "send closed by peer";
         end if;
         P := Last + 1;
      end loop;
   end Send_All;

   procedure Send_Frame
     (Sock : GNAT.Sockets.Socket_Type; B : Wire; Fd : Integer := -1)
   is
      use Ada.Streams;
      Marked : Wire (B'Range) := B;
      Item : constant Bytes (1 .. Stream_Element_Offset (B'Length)) :=
        Bytes (B);
      Iov  : aliased Iovec;
      Ctrl : aliased Cmsg_With_Fd;
      Msg  : aliased Msghdr;
      Sent : long;
   begin
      if Fd = -1 then
         Send_All (Sock, Item, 1);
         return;
      end if;

      --  Set the fd-attached bit in the header's length word (byte 8 is the
      --  most-significant byte of the little-endian length at offset 5).
      Marked (Marked'First + 7) :=
        Marked (Marked'First + 7) or Ada.Streams.Stream_Element (16#80#);

      Iov := (Iov_Base => Marked (Marked'First)'Address,
              Iov_Len  => size_t (Marked'Length));
      Ctrl := (Hdr => (Cmsg_Len   => Cmsg_Space,
                       Cmsg_Level => SOL_SOCKET,
                       Cmsg_Type  => SCM_RIGHTS),
               Fd  => int (Fd));
      Msg := (Msg_Name       => System.Null_Address,
              Msg_Namelen    => 0,
              Msg_Iov        => Iov'Address,
              Msg_Iovlen     => 1,
              Msg_Control    => Ctrl'Address,
              Msg_Controllen => Cmsg_Space,
              Msg_Flags      => 0);
      Sent := C_Sendmsg (int (GNAT.Sockets.To_C (Sock)), Msg'Access, 0);
      if Sent < 0 then
         raise Transport_Error with "sendmsg failed";
      end if;

      --  Send any unsent tail (rare over a socketpair) without the fd.
      Send_All (Sock, Item, Stream_Element_Offset (Sent) + 1);
   end Send_Frame;

   function Recv_Frame (Sock : GNAT.Sockets.Socket_Type) return Received is
      use Ada.Streams;
      Sfd      : constant int := int (GNAT.Sockets.To_C (Sock));
      Buf      : Bytes (1 .. Stream_Element_Offset (Max_Msg_Size));
      Iov      : aliased Iovec;
      Ctrl     : aliased Cmsg_With_Fd;
      Msg      : aliased Msghdr;
      Got      : long;
      Have_Off : Stream_Element_Offset;
      Fd       : Integer := -1;
      Raw_Len  : U32;
      Total    : Natural;
      Total_Off : Stream_Element_Offset;
   begin
      Iov := (Iov_Base => Buf (Buf'First)'Address,
              Iov_Len  => size_t (Buf'Length));
      Ctrl := (Hdr => (Cmsg_Len   => Cmsg_Space,
                       Cmsg_Level => SOL_SOCKET,
                       Cmsg_Type  => SCM_RIGHTS),
               Fd  => -1);
      Msg := (Msg_Name       => System.Null_Address,
              Msg_Namelen    => 0,
              Msg_Iov        => Iov'Address,
              Msg_Iovlen     => 1,
              Msg_Control    => Ctrl'Address,
              Msg_Controllen => Cmsg_Space,
              Msg_Flags      => 0);
      Got := C_Recvmsg (Sfd, Msg'Access, MSG_CMSG_CLOEXEC);
      if Got < 0 then
         raise Transport_Error with "recvmsg failed";
      elsif Got = 0 then
         raise Transport_Error with "receive closed by peer";
      end if;
      Have_Off := Stream_Element_Offset (Got);

      --  The kernel fills the cmsg and installs the descriptor; had the buffer
      --  been too small (it is not, for one fd) the fd is closed + MSG_CTRUNC.
      if Ctrl.Hdr.Cmsg_Len >= Cmsg_Space
        and then Ctrl.Hdr.Cmsg_Type = SCM_RIGHTS
      then
         Fd := Integer (Ctrl.Fd);
      end if;

      --  Complete the header if the first chunk was short of 16 bytes.
      if Have_Off < Stream_Element_Offset (Header_Size) then
         declare
            Rest : Bytes
              (1 .. Stream_Element_Offset (Header_Size) - Have_Off);
         begin
            Read_Exact (Sock, Rest);
            Buf (Have_Off + 1 .. Stream_Element_Offset (Header_Size)) := Rest;
            Have_Off := Stream_Element_Offset (Header_Size);
         end;
      end if;

      Raw_Len := (U32 (Buf (5)) * 2 ** 0
                  + U32 (Buf (6)) * 2 ** 8
                  + U32 (Buf (7)) * 2 ** 16
                  + U32 (Buf (8)) * 2 ** 24) and not IMSG_FD_Mark;
      if Raw_Len < U32 (Header_Size)
        or else Raw_Len > U32 (Max_Msg_Size)
      then
         raise Constraint_Error with "frame length out of range";
      end if;
      Total := Natural (Raw_Len);
      Total_Off := Stream_Element_Offset (Total);

      --  Read the rest of the payload (no further descriptor).
      if Have_Off < Total_Off then
         declare
            Rest : Bytes (1 .. Total_Off - Have_Off);
         begin
            Read_Exact (Sock, Rest);
            Buf (Have_Off + 1 .. Total_Off) := Rest;
         end;
      end if;

      return Received'
        (Length => Total,
         Fd     => Fd,
         Data   => Wire (Buf (1 .. Total_Off)));
   end Recv_Frame;

   procedure Send_Fd
     (Sock : GNAT.Sockets.Socket_Type;
      B    : Wire;
      Fd   : GNAT.Sockets.Socket_Type)
   is
   begin
      Send_Frame (Sock, B, GNAT.Sockets.To_C (Fd));
      GNAT.Sockets.Close_Socket (Fd);
   exception
      when others =>
         GNAT.Sockets.Close_Socket (Fd);
         raise;
   end Send_Fd;

end Imsg;
