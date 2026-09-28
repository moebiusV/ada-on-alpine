pragma Ada_2022;

with Ada.Unchecked_Deallocation;

with Interfaces.C;

package body Imsg is

   use Interfaces.C;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

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
   --  Receive_Socket returns a short count (Last < First) on a clean close,
   --  but raises Socket_Error on a reset/error; map the latter to
   --  Transport_Error so a dead channel always signals the same way.
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
            begin
               GNAT.Sockets.Receive_Socket (Sock, Rest, Last);
            exception
               when GNAT.Sockets.Socket_Error =>
                  raise Transport_Error
                    with "receive failed: peer closed or broken";
            end;
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
   --  A peer that has closed the connection makes Send_Socket raise
   --  GNAT.Sockets.Socket_Error (EPIPE), not return a short count, so map it
   --  to Transport_Error so every caller sees one consistent "channel is
   --  gone" signal.
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
         begin
            GNAT.Sockets.Send_Socket (Sock, B (P .. B'Last), Last);
         exception
            when GNAT.Sockets.Socket_Error =>
               raise Transport_Error with "send failed: peer closed or broken";
         end;
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

   ---------------------------------------------------------------
   --  Buffer: a growable byte buffer (the C ibuf)               --
   ---------------------------------------------------------------

   procedure Free_Array is new Ada.Unchecked_Deallocation
     (Payload, Payload_Access);

   --  Ensure B has room for Needed more bytes at the write cursor, growing the
   --  backing array to exactly Wpos + Needed when it must (matching
   --  ibuf_reserve, which reallocs to wpos + len).  Raises Constraint_Error
   --  past B.Max.
   procedure Grow (B : in out Buffer; Needed : Natural) is
      New_Cap  : constant Natural := B.Wpos + Needed;
      New_Data : Payload_Access;
   begin
      if Needed = 0 then
         return;
      end if;
      if New_Cap > B.Max then
         raise Constraint_Error with "ibuf: buffer too large";
      end if;
      if New_Cap > B.Cap then
         New_Data := new Payload (1 .. New_Cap);
         if B.Data /= null then
            New_Data.all (1 .. B.Cap) := B.Data.all (1 .. B.Cap);
            Free_Array (B.Data);
         end if;
         B.Data := New_Data;
         B.Cap := New_Cap;
      end if;
   end Grow;

   procedure Open_Buffer (B : out Buffer; Len : Natural := 0) is
   begin
      B.Data := (if Len > 0 then new Payload (1 .. Len) else null);
      B.Cap := Len;
      B.Wpos := 0;
      B.Rpos := 0;
      B.Max := Len;
      B.Fd := -1;
   end Open_Buffer;

   procedure Dynamic_Buffer (B : out Buffer; Len, Max : Natural) is
   begin
      if Max = 0 or else Max < Len then
         raise Constraint_Error with "ibuf_dynamic: bad max";
      end if;
      B.Data := (if Len > 0 then new Payload (1 .. Len) else null);
      B.Cap := Len;
      B.Wpos := 0;
      B.Rpos := 0;
      B.Max := Max;
      B.Fd := -1;
   end Dynamic_Buffer;

   procedure Reserve
     (B : in out Buffer; Len : Natural; Ptr : out System.Address)
   is
   begin
      Grow (B, Len);
      if Len > 0 then
         Ptr := B.Data.all (B.Wpos + 1)'Address;
      else
         Ptr := System.Null_Address;
      end if;
      B.Wpos := B.Wpos + Len;
   end Reserve;

   procedure Add (B : in out Buffer; Data : Payload) is
      N : constant Natural := Data'Length;
   begin
      Grow (B, N);
      if N > 0 then
         B.Data.all (B.Wpos + 1 .. B.Wpos + N) := Data;
      end if;
      B.Wpos := B.Wpos + N;
   end Add;

   procedure Add_U8 (B : in out Buffer; V : Interfaces.Unsigned_8) is
   begin
      Grow (B, 1);
      B.Data.all (B.Wpos + 1) := Ada.Streams.Stream_Element (V);
      B.Wpos := B.Wpos + 1;
   end Add_U8;

   procedure Add_U16_LE (B : in out Buffer; V : Interfaces.Unsigned_16) is
      P : constant Natural := B.Wpos;
   begin
      Grow (B, 2);
      B.Data.all (P + 1) := Ada.Streams.Stream_Element (V mod 256);
      B.Data.all (P + 2) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 8) mod 256);
      B.Wpos := P + 2;
   end Add_U16_LE;

   procedure Add_U32_LE (B : in out Buffer; V : Interfaces.Unsigned_32) is
      P : constant Natural := B.Wpos;
   begin
      Grow (B, 4);
      B.Data.all (P + 1) := Ada.Streams.Stream_Element (V mod 256);
      B.Data.all (P + 2) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 8) mod 256);
      B.Data.all (P + 3) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 16) mod 256);
      B.Data.all (P + 4) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 24) mod 256);
      B.Wpos := P + 4;
   end Add_U32_LE;

   procedure Add_U64_LE (B : in out Buffer; V : Interfaces.Unsigned_64) is
      P : constant Natural := B.Wpos;
      W : Interfaces.Unsigned_64 := V;
   begin
      Grow (B, 8);
      for I in 0 .. 7 loop
         B.Data.all (P + I + 1) := Ada.Streams.Stream_Element (W mod 256);
         W := Interfaces.Shift_Right (W, 8);
      end loop;
      B.Wpos := P + 8;
   end Add_U64_LE;

   procedure Add_U16_BE (B : in out Buffer; V : Interfaces.Unsigned_16) is
      P : constant Natural := B.Wpos;
   begin
      Grow (B, 2);
      B.Data.all (P + 1) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 8) mod 256);
      B.Data.all (P + 2) := Ada.Streams.Stream_Element (V mod 256);
      B.Wpos := P + 2;
   end Add_U16_BE;

   procedure Add_U32_BE (B : in out Buffer; V : Interfaces.Unsigned_32) is
      P : constant Natural := B.Wpos;
   begin
      Grow (B, 4);
      B.Data.all (P + 1) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 24) mod 256);
      B.Data.all (P + 2) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 16) mod 256);
      B.Data.all (P + 3) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 8) mod 256);
      B.Data.all (P + 4) := Ada.Streams.Stream_Element (V mod 256);
      B.Wpos := P + 4;
   end Add_U32_BE;

   procedure Add_U64_BE (B : in out Buffer; V : Interfaces.Unsigned_64) is
      P : constant Natural := B.Wpos;
      W : Interfaces.Unsigned_64 := V;
   begin
      Grow (B, 8);
      for I in 0 .. 7 loop
         B.Data.all (P + 8 - I) := Ada.Streams.Stream_Element (W mod 256);
         W := Interfaces.Shift_Right (W, 8);
      end loop;
      B.Wpos := P + 8;
   end Add_U64_BE;

   procedure Add_Zero (B : in out Buffer; Len : Natural) is
   begin
      Grow (B, Len);
      if Len > 0 then
         B.Data.all (B.Wpos + 1 .. B.Wpos + Len) := [others => 0];
      end if;
      B.Wpos := B.Wpos + Len;
   end Add_Zero;

   procedure Add_String (B : in out Buffer; S : String) is
      P : constant Natural := B.Wpos;
   begin
      Grow (B, S'Length);
      for I in S'Range loop
         B.Data.all (P + (I - S'First) + 1) :=
           Ada.Streams.Stream_Element (Character'Pos (S (I)));
      end loop;
      B.Wpos := P + S'Length;
   end Add_String;

   procedure Add_Ibuf (B : in out Buffer; From : Buffer) is
   begin
      Add (B, Data (From));
   end Add_Ibuf;

   procedure Add_Strbuf (B : in out Buffer; S : String; Len : Natural) is
      P : constant Natural := B.Wpos;
   begin
      if S'Length >= Len then
         raise Constraint_Error with "ibuf_add_strbuf: overflow";
      end if;
      Grow (B, Len);
      for I in S'Range loop
         B.Data.all (P + (I - S'First) + 1) :=
           Ada.Streams.Stream_Element (Character'Pos (S (I)));
      end loop;
      B.Data.all (P + S'Length + 1 .. P + Len) := [others => 0];
      B.Wpos := P + Len;
   end Add_Strbuf;

   function Data (B : Buffer) return Payload is
   begin
      if B.Data = null or else B.Wpos = B.Rpos then
         return [1 .. 0 => 0];
      end if;
      return B.Data.all (B.Rpos + 1 .. B.Wpos);
   end Data;

   function Size (B : Buffer) return Natural is
   begin
      return B.Wpos - B.Rpos;
   end Size;

   function Left (B : Buffer) return Natural is
   begin
      return B.Max - B.Wpos;
   end Left;

   procedure Truncate (B : in out Buffer; Len : Natural) is
      S : constant Natural := B.Wpos - B.Rpos;
   begin
      if S >= Len then
         B.Wpos := B.Rpos + Len;
      else
         Add_Zero (B, Len - S);
      end if;
   end Truncate;

   procedure Rewind (B : in out Buffer) is
   begin
      B.Rpos := 0;
   end Rewind;

   procedure Set_Bytes (B : in out Buffer; Pos : Natural; Data : Payload) is
      N : constant Natural := Data'Length;
   begin
      if Pos + N > B.Wpos - B.Rpos then
         raise Constraint_Error with "ibuf_set: out of range";
      end if;
      if N > 0 then
         B.Data.all (B.Rpos + Pos + 1 .. B.Rpos + Pos + N) := Data;
      end if;
   end Set_Bytes;

   function Set_Offset (B : Buffer; Pos, N : Natural) return Natural is
   begin
      if Pos + N > B.Wpos - B.Rpos then
         raise Constraint_Error with "ibuf_set: out of range";
      end if;
      return B.Rpos + Pos;
   end Set_Offset;

   procedure Set_U8
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_8) is
      O : constant Natural := Set_Offset (B, Pos, 1);
   begin
      B.Data.all (O + 1) := Ada.Streams.Stream_Element (V);
   end Set_U8;

   procedure Set_U16_LE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_16) is
      O : constant Natural := Set_Offset (B, Pos, 2);
   begin
      B.Data.all (O + 1) := Ada.Streams.Stream_Element (V mod 256);
      B.Data.all (O + 2) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 8) mod 256);
   end Set_U16_LE;

   procedure Set_U16_BE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_16) is
      O : constant Natural := Set_Offset (B, Pos, 2);
   begin
      B.Data.all (O + 1) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 8) mod 256);
      B.Data.all (O + 2) := Ada.Streams.Stream_Element (V mod 256);
   end Set_U16_BE;

   procedure Set_U32_LE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_32) is
      O : constant Natural := Set_Offset (B, Pos, 4);
   begin
      B.Data.all (O + 1) := Ada.Streams.Stream_Element (V mod 256);
      B.Data.all (O + 2) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 8) mod 256);
      B.Data.all (O + 3) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 16) mod 256);
      B.Data.all (O + 4) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 24) mod 256);
   end Set_U32_LE;

   procedure Set_U32_BE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_32) is
      O : constant Natural := Set_Offset (B, Pos, 4);
   begin
      B.Data.all (O + 1) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 24) mod 256);
      B.Data.all (O + 2) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 16) mod 256);
      B.Data.all (O + 3) := Ada.Streams.Stream_Element
        (Interfaces.Shift_Right (V, 8) mod 256);
      B.Data.all (O + 4) := Ada.Streams.Stream_Element (V mod 256);
   end Set_U32_BE;

   procedure Set_U64_LE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_64) is
      O : constant Natural := Set_Offset (B, Pos, 8);
      W : Interfaces.Unsigned_64 := V;
   begin
      for I in 0 .. 7 loop
         B.Data.all (O + I + 1) := Ada.Streams.Stream_Element (W mod 256);
         W := Interfaces.Shift_Right (W, 8);
      end loop;
   end Set_U64_LE;

   procedure Set_U64_BE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_64) is
      O : constant Natural := Set_Offset (B, Pos, 8);
      W : Interfaces.Unsigned_64 := V;
   begin
      for I in 0 .. 7 loop
         B.Data.all (O + 8 - I) := Ada.Streams.Stream_Element (W mod 256);
         W := Interfaces.Shift_Right (W, 8);
      end loop;
   end Set_U64_BE;

   procedure Set_Max_Size (B : in out Buffer; Max : Natural) is
   begin
      if Max > B.Max then
         raise Constraint_Error with "ibuf_set_maxsize: can only shrink";
      end if;
      if B.Wpos > Max then
         raise Constraint_Error with "ibuf_set_maxsize: below wpos";
      end if;
      B.Max := Max;
   end Set_Max_Size;

   procedure Get (B : in out Buffer; Data : out Payload) is
      N : constant Natural := Data'Length;
   begin
      if N > B.Wpos - B.Rpos then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      if N > 0 then
         Data := B.Data.all (B.Rpos + 1 .. B.Rpos + N);
         B.Rpos := B.Rpos + N;
      end if;
   end Get;

   procedure Get_U8 (B : in out Buffer; V : out Interfaces.Unsigned_8) is
   begin
      if 1 > B.Wpos - B.Rpos then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      V := Interfaces.Unsigned_8 (B.Data.all (B.Rpos + 1));
      B.Rpos := B.Rpos + 1;
   end Get_U8;

   procedure Get_U16_LE (B : in out Buffer; V : out Interfaces.Unsigned_16) is
      R : constant Natural := B.Rpos;
   begin
      if 2 > B.Wpos - R then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      V := Interfaces.Unsigned_16 (B.Data.all (R + 1))
         + Interfaces.Shift_Left
             (Interfaces.Unsigned_16 (B.Data.all (R + 2)), 8);
      B.Rpos := R + 2;
   end Get_U16_LE;

   procedure Get_U32_LE (B : in out Buffer; V : out Interfaces.Unsigned_32) is
      R : constant Natural := B.Rpos;
   begin
      if 4 > B.Wpos - R then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      V := Interfaces.Unsigned_32 (B.Data.all (R + 1))
         + Interfaces.Shift_Left
             (Interfaces.Unsigned_32 (B.Data.all (R + 2)), 8)
         + Interfaces.Shift_Left
             (Interfaces.Unsigned_32 (B.Data.all (R + 3)), 16)
         + Interfaces.Shift_Left
             (Interfaces.Unsigned_32 (B.Data.all (R + 4)), 24);
      B.Rpos := R + 4;
   end Get_U32_LE;

   procedure Get_U64_LE (B : in out Buffer; V : out Interfaces.Unsigned_64) is
      R : constant Natural := B.Rpos;
      Acc : Interfaces.Unsigned_64 := 0;
   begin
      if 8 > B.Wpos - R then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      for I in reverse 0 .. 7 loop
         Acc := Interfaces.Shift_Left (Acc, 8)
              + Interfaces.Unsigned_64 (B.Data.all (R + I + 1));
      end loop;
      V := Acc;
      B.Rpos := R + 8;
   end Get_U64_LE;

   procedure Get_U16_BE (B : in out Buffer; V : out Interfaces.Unsigned_16) is
      R : constant Natural := B.Rpos;
   begin
      if 2 > B.Wpos - R then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      V := Interfaces.Shift_Left
             (Interfaces.Unsigned_16 (B.Data.all (R + 1)), 8)
         + Interfaces.Unsigned_16 (B.Data.all (R + 2));
      B.Rpos := R + 2;
   end Get_U16_BE;

   procedure Get_U32_BE (B : in out Buffer; V : out Interfaces.Unsigned_32) is
      R : constant Natural := B.Rpos;
   begin
      if 4 > B.Wpos - R then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      V := Interfaces.Shift_Left
             (Interfaces.Unsigned_32 (B.Data.all (R + 1)), 24)
         + Interfaces.Shift_Left
             (Interfaces.Unsigned_32 (B.Data.all (R + 2)), 16)
         + Interfaces.Shift_Left
             (Interfaces.Unsigned_32 (B.Data.all (R + 3)), 8)
         + Interfaces.Unsigned_32 (B.Data.all (R + 4));
      B.Rpos := R + 4;
   end Get_U32_BE;

   procedure Get_U64_BE (B : in out Buffer; V : out Interfaces.Unsigned_64) is
      R : constant Natural := B.Rpos;
      Acc : Interfaces.Unsigned_64 := 0;
   begin
      if 8 > B.Wpos - R then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      for I in 0 .. 7 loop
         Acc := Interfaces.Shift_Left (Acc, 8)
              + Interfaces.Unsigned_64 (B.Data.all (R + I + 1));
      end loop;
      V := Acc;
      B.Rpos := R + 8;
   end Get_U64_BE;

   procedure Get_String (B : in out Buffer; S : out String) is
      R : constant Natural := B.Rpos;
      N : constant Natural := S'Length;
   begin
      if N > B.Wpos - R then
         raise Constraint_Error with "ibuf_get: short buffer";
      end if;
      for I in S'Range loop
         S (I) := Character'Val (Natural (B.Data.all (R + (I - S'First) + 1)));
      end loop;
      B.Rpos := R + N;
   end Get_String;

   procedure Skip (B : in out Buffer; Len : Natural) is
   begin
      if Len > B.Wpos - B.Rpos then
         raise Constraint_Error with "ibuf_skip: short buffer";
      end if;
      B.Rpos := B.Rpos + Len;
   end Skip;

   procedure From_Buffer (B : out Buffer; Data : Payload) is
   begin
      Open_Buffer (B, Data'Length);
      Add (B, Data);
   end From_Buffer;

   procedure From_Ibuf (B : out Buffer; From : Buffer) is
   begin
      From_Buffer (B, Data (From));
   end From_Ibuf;

   procedure Get_Ibuf (B : in out Buffer; Len : Natural; New_B : out Buffer) is
   begin
      if Len > B.Wpos - B.Rpos then
         raise Constraint_Error with "ibuf_get_ibuf: short buffer";
      end if;
      if Len = 0 then
         Open_Buffer (New_B, 0);
      else
         From_Buffer (New_B, B.Data.all (B.Rpos + 1 .. B.Rpos + Len));
      end if;
      B.Rpos := B.Rpos + Len;
   end Get_Ibuf;

   procedure Attach_Fd (B : in out Buffer; Fd : Integer) is
   begin
      if B.Fd >= 0 then
         GNAT.Sockets.Close_Socket (GNAT.Sockets.To_Ada (B.Fd));
      end if;
      B.Fd := (if Fd >= 0 then Fd else -1);
   end Attach_Fd;

   function Take_Fd (B : in out Buffer) return Integer is
      Fd : constant Integer := B.Fd;
   begin
      B.Fd := -1;
      if Fd < 0 then
         return -1;
      end if;
      return Fd;
   end Take_Fd;

   function Has_Fd (B : Buffer) return Boolean is
   begin
      return B.Fd >= 0;
   end Has_Fd;

   procedure Free (B : in out Buffer) is
   begin
      if B.Data /= null then
         B.Data.all := [others => 0];  --  freezero: zero before releasing
         Free_Array (B.Data);
      end if;
      if B.Fd >= 0 then
         GNAT.Sockets.Close_Socket (GNAT.Sockets.To_Ada (B.Fd));
      end if;
      B.Cap := 0;
      B.Wpos := 0;
      B.Rpos := 0;
      B.Max := 0;
      B.Fd := -1;
   end Free;

   ---------------------------------------------------------------
   --  Connection: a buffered imsg channel (the C imsgbuf)       --
   ---------------------------------------------------------------

   procedure Free_Buffer is new Ada.Unchecked_Deallocation
     (Buffer, Buffer_Access);

   function C_Getpid return int;
   pragma Import (C, C_Getpid, "getpid");

   procedure Initialize
     (C : out Connection; Sock : GNAT.Sockets.Socket_Type) is
   begin
      C.Sock := Sock;
      C.Write_Q := Buffer_Vectors.Empty_Vector;
      C.Read_Q := Buffer_Vectors.Empty_Vector;
      C.Read_Buf := new Payload (1 .. Read_Size);
      C.Read_Len := 0;
      C.Pending := null;
      C.Allow_Fd := False;
      C.Max_Size := Max_Msg_Size;
      C.Pid := Natural (C_Getpid);
      C.Userdata := System.Null_Address;
      C.Cb := null;
   end Initialize;

   procedure Allow_Fd_Pass (C : in out Connection) is
   begin
      C.Allow_Fd := True;
   end Allow_Fd_Pass;

   procedure Set_Max_Size (C : in out Connection; Max : Natural) is
      Total : constant Natural := Max + Header_Size;
   begin
      if (U32 (Total) and IMSG_FD_Mark) /= 0 then
         raise Constraint_Error with "max size too large";
      end if;
      C.Max_Size := Total;
   end Set_Max_Size;

   procedure Write (C : in out Connection) is
   begin
      while not C.Write_Q.Is_Empty loop
         declare
            Msg : Buffer_Access := C.Write_Q.First_Element;
         begin
            C.Write_Q.Delete_First;
            declare
               Wire_Bytes : constant Payload := Data (Msg.all);
               Fd         : constant Integer := Take_Fd (Msg.all);
            begin
               Send_Frame (C.Sock, Wire_Bytes, Fd);
               if Fd >= 0 then
                  GNAT.Sockets.Close_Socket (GNAT.Sockets.To_Ada (Fd));
               end if;
            end;
            Free (Msg.all);
            Free_Buffer (Msg);
         end;
      end loop;
   end Write;

   procedure Flush (C : in out Connection) is
   begin
      Write (C);
   end Flush;

   procedure Clear (C : in out Connection) is
   begin
      while not C.Write_Q.Is_Empty loop
         declare
            Msg : Buffer_Access := C.Write_Q.First_Element;
         begin
            C.Write_Q.Delete_First;
            Free (Msg.all);
            Free_Buffer (Msg);
         end;
      end loop;
      while not C.Read_Q.Is_Empty loop
         declare
            Msg : Buffer_Access := C.Read_Q.First_Element;
         begin
            C.Read_Q.Delete_First;
            Free (Msg.all);
            Free_Buffer (Msg);
         end;
      end loop;
      if C.Pending /= null then
         Free (C.Pending.all);
         Free_Buffer (C.Pending);
         C.Pending := null;
      end if;
      if C.Read_Buf /= null then
         C.Read_Buf.all := [others => 0];  --  freezero: zero before releasing
         Free_Array (C.Read_Buf);
         C.Read_Buf := null;
      end if;
      C.Read_Len := 0;
   end Clear;

   function Queue_Length (C : Connection) return Natural is
   begin
      return Natural (C.Write_Q.Length);
   end Queue_Length;

   procedure Read (C : in out Connection) is
      Incoming_Fd : Integer := -1;
      Off         : Natural;
      Got         : long;
      Sfd         : constant int := int (GNAT.Sockets.To_C (C.Sock));
      Iov         : aliased Iovec;
      Ctrl        : aliased Cmsg_With_Fd;
      Msg         : aliased Msghdr;
   begin
      if C.Read_Buf = null then
         C.Read_Buf := new Payload (1 .. Read_Size);
      end if;

      --  Receive into the free tail of Read_Buf, capturing a descriptor.
      Iov := (Iov_Base => C.Read_Buf.all (C.Read_Len + 1)'Address,
              Iov_Len  => size_t (Read_Size - C.Read_Len));
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
         raise Connection_Closed;
      end if;
      if Ctrl.Hdr.Cmsg_Len >= Cmsg_Space
        and then Ctrl.Hdr.Cmsg_Type = SCM_RIGHTS
      then
         Incoming_Fd := Integer (Ctrl.Fd);
      end if;
      C.Read_Len := C.Read_Len + Natural (Got);

      --  Split Read_Buf (1 .. Read_Len) into complete messages.
      Off := 1;
      loop
         if C.Pending = null then
            if C.Read_Len - Off + 1 < Header_Size then
               exit;   --  need the rest of the header
            end if;
            declare
               Raw    : constant U32 := Get_U32 (C.Read_Buf.all, Off + 4);
               Has_Fd : constant Boolean := (Raw and IMSG_FD_Mark) /= 0;
               Total  : constant Natural := Natural (Raw and not IMSG_FD_Mark);
            begin
               if Total < Header_Size or else Total > C.Max_Size then
                  raise Constraint_Error with "frame length out of range";
               end if;
               C.Pending := new Buffer;
               Open_Buffer (C.Pending.all, Total);
               if Has_Fd then
                  Attach_Fd (C.Pending.all, Incoming_Fd);
                  Incoming_Fd := -1;
               end if;
            end;
         end if;

         declare
            Avail : constant Natural := C.Read_Len - Off + 1;
            Need  : constant Natural := C.Pending.all.Max - C.Pending.all.Wpos;
            Take  : Natural;
         begin
            if Need < Avail then
               Take := Need;
            else
               Take := Avail;
            end if;
            Add (C.Pending.all, C.Read_Buf.all (Off .. Off + Take - 1));
            Off := Off + Take;
         end;

         if C.Pending.all.Wpos = C.Pending.all.Max then
            C.Read_Q.Append (C.Pending);
            C.Pending := null;
         else
            exit;   --  message incomplete; wait for more bytes
         end if;
      end loop;

      --  Move the unconsumed tail to the front of Read_Buf.
      if Off <= C.Read_Len then
         declare
            Leftover : constant Natural := C.Read_Len - Off + 1;
         begin
            C.Read_Buf.all (1 .. Leftover) :=
              C.Read_Buf.all (Off .. C.Read_Len);
            C.Read_Len := Leftover;
         end;
      else
         C.Read_Len := 0;
      end if;

      if Incoming_Fd /= -1 then
         GNAT.Sockets.Close_Socket (GNAT.Sockets.To_Ada (Incoming_Fd));
      end if;
   end Read;

   function Get (C : in out Connection) return Received is
      Msg : Buffer_Access;
   begin
      if C.Read_Q.Is_Empty then
         raise Not_Complete;
      end if;
      Msg := C.Read_Q.First_Element;
      C.Read_Q.Delete_First;
      declare
         Wire_Bytes : constant Payload := Data (Msg.all);
         Fd         : constant Integer := Take_Fd (Msg.all);
      begin
         Free (Msg.all);
         Free_Buffer (Msg);
         return Received'(Length => Wire_Bytes'Length,
                          Fd     => Fd,
                          Data   => Wire_Bytes);
      end;
   end Get;

   function Compose_Buffer
     (C           : in out Connection;
      Kind        : Message_Type;
      Data_Length : Natural;
      Peer        : Peer_Id := 0;
      Pid         : Pid_Type := 0) return Buffer_Access
   is
      Total   : constant Natural := Header_Size + Data_Length;
      B       : Buffer_Access;
      Use_Pid : Pid_Type := Pid;
   begin
      if Total > C.Max_Size then
         raise Constraint_Error with "message too large";
      end if;
      if Use_Pid = 0 then
         Use_Pid := Pid_Type (C.Pid);
      end if;
      B := new Buffer;
      Dynamic_Buffer (B.all, Total, C.Max_Size);
      Add_U32_LE (B.all, Interfaces.Unsigned_32 (Kind));
      Add_U32_LE (B.all, 0);   --  length placeholder, set in Close
      Add_U32_LE (B.all, Interfaces.Unsigned_32 (Peer));
      Add_U32_LE (B.all, Interfaces.Unsigned_32 (Use_Pid));
      return B;
   end Compose_Buffer;

   procedure Close (C : in out Connection; Msg : in out Buffer_Access) is
   begin
      if Msg = null then
         raise Constraint_Error with "imsg_close: null buffer";
      end if;
      --  Write the total frame size into the 16-byte header's length field
      --  (the 0-indexed offset 4, matching offsetof(struct imsg_hdr, len)).
      Set_U32_LE (Msg.all, 4, Interfaces.Unsigned_32 (Size (Msg.all)));
      C.Write_Q.Append (Msg);
      Msg := null;
      if C.Cb /= null then
         C.Cb (C.Userdata);
      end if;
   end Close;

   procedure Compose
     (C    : in out Connection;
      Kind : Message_Type;
      Peer : Peer_Id := 0;
      Pid  : Pid_Type := 0;
      Fd   : Integer  := -1;
      Data : Payload  := [1 .. 0 => 0])
   is
      Msg : Buffer_Access;
   begin
      Msg := Compose_Buffer (C, Kind, Data'Length, Peer, Pid);
      Add (Msg.all, Data);
      if Fd >= 0 then
         Attach_Fd (Msg.all, Fd);
      end if;
      Close (C, Msg);
   end Compose;

   procedure Forward (C : in out Connection; Msg : Received) is
      F : constant Frame := Decode (Msg.Data);
   begin
      if Msg.Fd >= 0 then
         GNAT.Sockets.Close_Socket (GNAT.Sockets.To_Ada (Msg.Fd));
      end if;
      Compose (C, F.Kind, F.Peer, F.Pid, -1, F.Data);
   end Forward;

   procedure Compose_V
     (C     : in out Connection;
      Kind  : Message_Type;
      Peer  : Peer_Id := 0;
      Pid   : Pid_Type := 0;
      Fd    : Integer  := -1;
      Parts : Payload_Vectors.Vector)
   is
      Total : Natural := 0;
      Msg   : Buffer_Access;
   begin
      for P of Parts loop
         Total := Total + P'Length;
      end loop;
      Msg := Compose_Buffer (C, Kind, Total, Peer, Pid);
      for P of Parts loop
         Add (Msg.all, P);
      end loop;
      if Fd >= 0 then
         Attach_Fd (Msg.all, Fd);
      end if;
      Close (C, Msg);
   end Compose_V;

   procedure Set_Userdata (C : in out Connection; Ptr : System.Address) is
   begin
      C.Userdata := Ptr;
   end Set_Userdata;

   function Get_Userdata (C : Connection) return System.Address is
   begin
      return C.Userdata;
   end Get_Userdata;

   procedure Set_Close_Callback (C : in out Connection; Cb : Close_Callback) is
   begin
      C.Cb := Cb;
   end Set_Close_Callback;

end Imsg;
