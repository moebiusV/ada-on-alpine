pragma Ada_2022;

with Ada.Text_IO;
with GNAT.Sockets;
with Imsg;
with Interfaces;

--  Imsg example: the wire codec (Encode/Decode) and a buffered Connection over
--  a socketpair.  A C peer using the portable imsg.c would interoperate with
--  these frames byte-for-byte.
procedure Imsg_Example is

   use type Interfaces.Unsigned_32;

   --  Build a frame from a message type and payload.
   function Mk (Kind : Imsg.Message_Type; Data : Imsg.Payload) return Imsg.Frame is
      F : Imsg.Frame (Data'Length);
   begin
      F.Kind := Kind;
      F.Peer := 0;
      F.Pid  := 42;
      F.Data := Data;
      return F;
   end Mk;

begin
   --  Codec: a frame encodes to its wire form and decodes back identically.
   declare
      F : constant Imsg.Frame := Mk (1, [16#68#, 16#69#]);   --  "hi"
      D : constant Imsg.Frame := Imsg.Decode (Imsg.Encode (F));
   begin
      Ada.Text_IO.Put_Line
        ("codec: kind=" & Imsg.Message_Type'Image (D.Kind)
         & " pid=" & Imsg.Pid_Type'Image (D.Pid)
         & " payload=" & Natural'Image (D.Data'Length) & " bytes");
   end;

   --  Connection: a buffered channel over one connected socketpair.
   declare
      A, B : GNAT.Sockets.Socket_Type;
      Ca   : Imsg.Connection;
      Cb   : Imsg.Connection;
   begin
      GNAT.Sockets.Create_Socket_Pair (A, B);
      Imsg.Initialize (Ca, A);
      Imsg.Initialize (Cb, B);

      --  Sender: compose a message with a typed little-endian field, then send.
      declare
         Mb : Imsg.Buffer_Access := Imsg.Compose_Buffer (Ca, 7, 4, 0, 0);
      begin
         Imsg.Add_U32_LE (Mb.all, 16#DEAD_BEEF#);
         Imsg.Close (Ca, Mb);
      end;
      Imsg.Flush (Ca);

      --  Receiver: read the buffered bytes and get the next complete message.
      Imsg.Read (Cb);
      declare
         R : constant Imsg.Received := Imsg.Get (Cb);
         F : constant Imsg.Frame := Imsg.Decode (R.Data);
      begin
         Ada.Text_IO.Put_Line
           ("received: kind=" & Imsg.Message_Type'Image (F.Kind)
            & " payload=" & Natural'Image (F.Data'Length) & " bytes"
            & " fd=" & Integer'Image (R.Fd));
      end;
   end;
end Imsg_Example;
