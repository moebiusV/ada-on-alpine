pragma Ada_2022;

with Ada.Command_Line;
with Ada.Streams;
with Ada.Text_IO;
with GNAT.Sockets;
with Imsg;

procedure Imsg_Check is

   use type Imsg.Message_Type;
   use type Imsg.Peer_Id;
   use type Imsg.Pid_Type;
   use type Imsg.Payload;

   Failures : Natural := 0;
   Checks   : Natural := 0;

   function Mk
     (Kind : Imsg.Message_Type;
      Peer : Imsg.Peer_Id;
      Pid  : Imsg.Pid_Type;
      Data : Imsg.Payload) return Imsg.Frame is
      F : Imsg.Frame (Data'Length);
   begin
      F.Kind := Kind;
      F.Peer := Peer;
      F.Pid  := Pid;
      F.Data := Data;
      return F;
   end Mk;

   function Frame_Equal (A, B : Imsg.Frame) return Boolean is
   begin
      return A.Length = B.Length
        and then A.Kind = B.Kind
        and then A.Peer = B.Peer
        and then A.Pid = B.Pid
        and then A.Data = B.Data;
   end Frame_Equal;

   procedure Check_Roundtrip (Name : String; F : Imsg.Frame) is
      OK : constant Boolean :=
        Frame_Equal (F, Imsg.Decode (Imsg.Encode (F)));
   begin
      Checks := Checks + 1;
      if OK then
         Ada.Text_IO.Put_Line ("ok: " & Name);
      else
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
      end if;
   end Check_Roundtrip;

   procedure Check_Bytes (Name : String; F : Imsg.Frame; E : Imsg.Wire) is
      Got : constant Imsg.Wire := Imsg.Encode (F);
   begin
      Checks := Checks + 1;
      if Got = E then
         Ada.Text_IO.Put_Line ("ok: " & Name);
      else
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
      end if;
   end Check_Bytes;

   procedure Check_Raises (Name : String; B : Imsg.Wire) is
   begin
      Checks := Checks + 1;
      begin
         declare
            Dummy : constant Imsg.Frame := Imsg.Decode (B);
         begin
            Failures := Failures + 1;
            Ada.Text_IO.Put_Line
              ("FAIL: " & Name & " (decoded, length" &
               Natural'Image (Dummy.Length) & ")");
         end;
      exception
         when Constraint_Error =>
            Ada.Text_IO.Put_Line ("ok: " & Name);
      end;
   end Check_Raises;

   procedure Check_Transport is
      A, B : GNAT.Sockets.Socket_Type;
      F    : constant Imsg.Frame := Mk (99, 0, 0, [16#01#, 16#02#, 16#03#]);
      W    : constant Imsg.Wire := Imsg.Encode (F);
      Got  : Imsg.Wire (W'Range);
   begin
      GNAT.Sockets.Create_Socket_Pair (A, B);
      Imsg.Send_Frame (A, W);
      Got := Imsg.Recv_Frame (B).Data;
      Checks := Checks + 1;
      if Got = W then
         Ada.Text_IO.Put_Line ("ok: transport round-trip");
      else
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("FAIL: transport round-trip");
      end if;
      GNAT.Sockets.Close_Socket (A);
      GNAT.Sockets.Close_Socket (B);
   end Check_Transport;

   procedure Check_Fd_Passing is
      use Ada.Streams;
      A, B : GNAT.Sockets.Socket_Type;   --  transport pair
      X, Y : GNAT.Sockets.Socket_Type;   --  the descriptor to pass
      F    : constant Imsg.Frame := Mk (42, 0, 0, [16#42#]);
      W    : constant Imsg.Wire := Imsg.Encode (F);
   begin
      GNAT.Sockets.Create_Socket_Pair (A, B);
      GNAT.Sockets.Create_Socket_Pair (X, Y);
      Imsg.Send_Frame (A, W, GNAT.Sockets.To_C (X));
      GNAT.Sockets.Close_Socket (X);

      declare
         R : constant Imsg.Received := Imsg.Recv_Frame (B);
      begin
         Checks := Checks + 1;
         if R.Fd < 0 then
            Failures := Failures + 1;
            Ada.Text_IO.Put_Line ("FAIL: fd passing (no descriptor)");
         elsif not Frame_Equal (Imsg.Decode (R.Data), F) then
            Failures := Failures + 1;
            Ada.Text_IO.Put_Line ("FAIL: fd passing (data mismatch)");
         else
            --  The descriptor must be a live duplicate of X: a byte written
            --  to Y arrives on it.
            declare
               Rfds : GNAT.Sockets.Socket_Type :=
                 GNAT.Sockets.To_Ada (R.Fd);
               Got  : Stream_Element_Array (1 .. 1);
               Last : Stream_Element_Offset;
            begin
               GNAT.Sockets.Send_Socket (Y, [16#5A#], Last);
               GNAT.Sockets.Receive_Socket (Rfds, Got, Last);
               if Last >= Got'First and then Got (1) = 16#5A# then
                  Ada.Text_IO.Put_Line ("ok: fd passing");
               else
                  Failures := Failures + 1;
                  Ada.Text_IO.Put_Line
                    ("FAIL: fd passing (dead descriptor)");
               end if;
               GNAT.Sockets.Close_Socket (Rfds);
            end;
         end if;
      end;

      GNAT.Sockets.Close_Socket (Y);
      GNAT.Sockets.Close_Socket (A);
      GNAT.Sockets.Close_Socket (B);
   end Check_Fd_Passing;

   procedure Check_Send_Fd is
      use Ada.Streams;
      A, B : GNAT.Sockets.Socket_Type;   --  transport pair
      X, Y : GNAT.Sockets.Socket_Type;   --  the descriptor to hand over
      F    : constant Imsg.Frame := Mk (43, 0, 0, [16#43#]);
      W    : constant Imsg.Wire := Imsg.Encode (F);
   begin
      GNAT.Sockets.Create_Socket_Pair (A, B);
      GNAT.Sockets.Create_Socket_Pair (X, Y);
      Imsg.Send_Fd (A, W, X);            --  hands X over + closes it here

      declare
         R : constant Imsg.Received := Imsg.Recv_Frame (B);
      begin
         Checks := Checks + 1;
         if R.Fd < 0 then
            Failures := Failures + 1;
            Ada.Text_IO.Put_Line ("FAIL: Send_Fd handoff (no descriptor)");
         elsif not Frame_Equal (Imsg.Decode (R.Data), F) then
            Failures := Failures + 1;
            Ada.Text_IO.Put_Line ("FAIL: Send_Fd handoff (data mismatch)");
         else
            --  The handed-over descriptor is a live duplicate of X: a byte
            --  written to Y arrives on it.
            declare
               Rfds : GNAT.Sockets.Socket_Type :=
                 GNAT.Sockets.To_Ada (R.Fd);
               Got  : Stream_Element_Array (1 .. 1);
               Last : Stream_Element_Offset;
            begin
               GNAT.Sockets.Send_Socket (Y, [16#5B#], Last);
               GNAT.Sockets.Receive_Socket (Rfds, Got, Last);
               if Last >= Got'First and then Got (1) = 16#5B# then
                  Ada.Text_IO.Put_Line ("ok: Send_Fd handoff");
               else
                  Failures := Failures + 1;
                  Ada.Text_IO.Put_Line
                    ("FAIL: Send_Fd handoff (dead descriptor)");
               end if;
               GNAT.Sockets.Close_Socket (Rfds);
            end;
         end if;
      end;

      GNAT.Sockets.Close_Socket (Y);
      GNAT.Sockets.Close_Socket (A);
      GNAT.Sockets.Close_Socket (B);
   end Check_Send_Fd;

begin
   Check_Roundtrip
     ("empty payload",
      Mk (1, 2, 3, [1 .. 0 => 0]));
   Check_Roundtrip
     ("small payload",
      Mk (7, 8, 9, [16#AA#, 16#BB#, 16#CC#]));
   Check_Roundtrip
     ("multi-byte payload",
      Mk (1, 0, 0, [1 .. 256 => 16#5A#]));

   --  Explicit little-endian field layout, matching portable imsg.c: type
   --  0x01020304, length 18 (16-byte header + 2 payload), peer/pid 0,
   --  payload 0xAA 0xBB.
   Check_Bytes
     ("little-endian header layout",
      Mk (16#01020304#, 0, 0, [16#AA#, 16#BB#]),
      [4, 3, 2, 1, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16#AA#, 16#BB#]);

   Check_Raises ("short header", [1, 2, 3]);
   Check_Raises
     ("oversized length",
      [0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0]);
   Check_Raises
     ("length mismatch",
      [0, 0, 0, 1, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

   Check_Transport;
   Check_Fd_Passing;
   Check_Send_Fd;

   Ada.Text_IO.Put_Line
     ("checks: " & Natural'Image (Checks) &
      ", failures: " & Natural'Image (Failures));
   if Failures = 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Imsg_Check;
