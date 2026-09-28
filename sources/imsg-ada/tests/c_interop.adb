pragma Ada_2022;

--  c_interop: decode a frame composed by the C harness (tests/c_compose.c) and
--  written to the file named by argv(1), then verify every field -- proving
--  the Ada codec agrees with portable imsg.c's wire format byte-for-byte.

with Ada.Command_Line;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;
with Imsg;

procedure C_Interop is
   use Ada.Streams;
   use type Imsg.Message_Type;
   use type Imsg.Peer_Id;
   use type Imsg.Pid_Type;
   use type Imsg.Payload;

   File  : Ada.Streams.Stream_IO.File_Type;
   S     : Ada.Streams.Stream_IO.Stream_Access;
   Bytes : Stream_Element_Array (1 .. 1024);
   Last  : Stream_Element_Offset;
   Ok    : Boolean := True;

   procedure Check (Name : String; Cond : Boolean) is
   begin
      if Cond then
         Ada.Text_IO.Put_Line ("ok: " & Name);
      else
         Ok := False;
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
      end if;
   end Check;
begin
   Ada.Streams.Stream_IO.Open
     (File, Ada.Streams.Stream_IO.In_File, Ada.Command_Line.Argument (1));
   S := Ada.Streams.Stream_IO.Stream (File);
   Ada.Streams.Read (S.all, Bytes, Last);
   Ada.Streams.Stream_IO.Close (File);

   declare
      F : constant Imsg.Frame := Imsg.Decode (Imsg.Wire (Bytes (1 .. Last)));
   begin
      Check ("c interop kind", F.Kind = 16#01020304#);
      Check ("c interop peer", F.Peer = 5);
      Check ("c interop pid", F.Pid = 6);
      Check ("c interop payload", F.Data = [16#AA#, 16#BB#, 16#CC#]);
   end;

   if Ok then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end C_Interop;
