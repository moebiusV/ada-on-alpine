pragma Ada_2022;

package body Imsg is

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

   procedure Send_Frame (Sock : GNAT.Sockets.Socket_Type; B : Wire) is
      use Ada.Streams;
      Item : constant Bytes
        (1 .. Stream_Element_Offset (B'Length)) := Bytes (B);
      Pos  : Stream_Element_Offset := 1;
      Last : Stream_Element_Offset;
   begin
      while Pos <= Item'Last loop
         GNAT.Sockets.Send_Socket (Sock, Item (Pos .. Item'Last), Last);
         if Last < Pos then
            raise Transport_Error with "send closed by peer";
         end if;
         Pos := Last + 1;
      end loop;
   end Send_Frame;

   function Recv_Frame (Sock : GNAT.Sockets.Socket_Type) return Wire is
      use Ada.Streams;
      Hdr     : Bytes (1 .. Stream_Element_Offset (Header_Size));
      Raw_Len : U32;
      Total   : Natural;
   begin
      Read_Exact (Sock, Hdr);
      Raw_Len := (U32 (Hdr (5)) * 2 ** 0
                  + U32 (Hdr (6)) * 2 ** 8
                  + U32 (Hdr (7)) * 2 ** 16
                  + U32 (Hdr (8)) * 2 ** 24) and not IMSG_FD_Mark;
      if Raw_Len < U32 (Header_Size)
        or else Raw_Len > U32 (Max_Msg_Size)
      then
         raise Constraint_Error with "frame length out of range";
      end if;
      Total := Natural (Raw_Len);
      declare
         Full : Bytes (1 .. Stream_Element_Offset (Total));
      begin
         Full (1 .. Hdr'Last) := Hdr;
         if Total > Header_Size then
            declare
               Rest : Bytes
                 (1 .. Stream_Element_Offset (Total - Header_Size));
            begin
               Read_Exact (Sock, Rest);
               Full (Stream_Element_Offset (Header_Size) + 1 .. Full'Last)
                 := Rest;
            end;
         end if;
         return Wire (Full);
      end;
   end Recv_Frame;

end Imsg;
