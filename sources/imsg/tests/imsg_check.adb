pragma Ada_2022;

with Ada.Command_Line;
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
      Got := Imsg.Recv_Frame (B);
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

   Ada.Text_IO.Put_Line
     ("checks: " & Natural'Image (Checks) &
      ", failures: " & Natural'Image (Failures));
   if Failures = 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Imsg_Check;
