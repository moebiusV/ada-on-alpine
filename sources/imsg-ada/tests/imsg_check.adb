pragma Ada_2022;

with Ada.Command_Line;
with Ada.Streams;
with Ada.Text_IO;
with GNAT.Sockets;
with Imsg;
with Interfaces;

procedure Imsg_Check is

   use type Imsg.Message_Type;
   use type Imsg.Peer_Id;
   use type Imsg.Pid_Type;
   use type Imsg.Payload;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

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

   procedure Pass (Name : String; OK : Boolean) is
   begin
      Checks := Checks + 1;
      if OK then
         Ada.Text_IO.Put_Line ("ok: " & Name);
      else
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
      end if;
   end Pass;

   --  A peer that has closed its end: sends and receives must both signal
   --  Transport_Error (not the raw GNAT.Sockets.Socket_Error), so a caller
   --  sees one consistent "channel gone" exception.
   procedure Check_Closed_Peer is
      A, B             : GNAT.Sockets.Socket_Type;
      F                : constant Imsg.Frame := Mk (50, 0, 0, [16#01#, 16#02#]);
      W                : constant Imsg.Wire := Imsg.Encode (F);
      Sent_Ok, Recv_Ok : Boolean := False;
   begin
      GNAT.Sockets.Create_Socket_Pair (A, B);
      GNAT.Sockets.Close_Socket (B);

      begin
         Imsg.Send_Frame (A, W);
      exception
         when Imsg.Transport_Error =>
            Sent_Ok := True;
         when others =>
            null;
      end;
      Pass ("closed peer: send raises Transport_Error", Sent_Ok);

      begin
         declare
            R : constant Imsg.Received := Imsg.Recv_Frame (A);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Imsg.Transport_Error =>
            Recv_Ok := True;
         when others =>
            null;
      end;
      Pass ("closed peer: recv raises Transport_Error", Recv_Ok);

      GNAT.Sockets.Close_Socket (A);
   end Check_Closed_Peer;

   procedure Check_Buffer is
      B    : Imsg.Buffer;
      U8   : Interfaces.Unsigned_8;
      U16  : Interfaces.Unsigned_16;
      U32v : Interfaces.Unsigned_32;
      U64v : Interfaces.Unsigned_64;
      Str  : String (1 .. 5);
   begin
      --  typed little-endian round-trips
      Imsg.Dynamic_Buffer (B, 0, 64);
      Imsg.Add_U8 (B, 16#AA#);
      Imsg.Add_U16_LE (B, 16#1234#);
      Imsg.Add_U32_LE (B, 16#12345678#);
      Imsg.Add_U64_LE (B, 16#0102030405060708#);
      Pass ("buffer size", Imsg.Size (B) = 15);
      Imsg.Rewind (B);
      Imsg.Get_U8 (B, U8);
      Imsg.Get_U16_LE (B, U16);
      Imsg.Get_U32_LE (B, U32v);
      Imsg.Get_U64_LE (B, U64v);
      Pass ("buffer U8", U8 = 16#AA#);
      Pass ("buffer U16 LE", U16 = 16#1234#);
      Pass ("buffer U32 LE", U32v = 16#12345678#);
      Pass ("buffer U64 LE", U64v = 16#0102030405060708#);
      Imsg.Free (B);

      --  typed big-endian round-trips
      Imsg.Dynamic_Buffer (B, 0, 64);
      Imsg.Add_U16_BE (B, 16#1234#);
      Imsg.Add_U32_BE (B, 16#12345678#);
      Imsg.Add_U64_BE (B, 16#0102030405060708#);
      Imsg.Rewind (B);
      Imsg.Get_U16_BE (B, U16);
      Imsg.Get_U32_BE (B, U32v);
      Imsg.Get_U64_BE (B, U64v);
      Pass ("buffer U16 BE", U16 = 16#1234#);
      Pass ("buffer U32 BE", U32v = 16#12345678#);
      Pass ("buffer U64 BE", U64v = 16#0102030405060708#);
      Imsg.Free (B);

      --  explicit byte layouts
      Imsg.Dynamic_Buffer (B, 0, 16);
      Imsg.Add_U32_LE (B, 16#01020304#);
      Pass ("buffer U32 LE layout",
        Imsg.Data (B) = [16#04#, 16#03#, 16#02#, 16#01#]);
      Imsg.Free (B);
      Imsg.Dynamic_Buffer (B, 0, 16);
      Imsg.Add_U32_BE (B, 16#01020304#);
      Pass ("buffer U32 BE layout",
        Imsg.Data (B) = [16#01#, 16#02#, 16#03#, 16#04#]);
      Imsg.Free (B);

      --  string round-trip
      Imsg.Dynamic_Buffer (B, 0, 16);
      Imsg.Add_String (B, "hello");
      Imsg.Rewind (B);
      Imsg.Get_String (B, Str);
      Pass ("buffer string", Str = "hello");
      Imsg.Free (B);

      --  set-at-position writes at Rpos + Pos (0-indexed offset)
      Imsg.Dynamic_Buffer (B, 16, 16);
      Imsg.Add_Zero (B, 16);
      Imsg.Set_U32_LE (B, 4, 1234);
      Imsg.Rewind (B);
      Imsg.Skip (B, 4);
      Imsg.Get_U32_LE (B, U32v);
      Pass ("buffer set_u32_le", U32v = 1234);
      Imsg.Free (B);

      --  big-endian set round-trip
      Imsg.Dynamic_Buffer (B, 0, 16);
      Imsg.Add_Zero (B, 8);
      Imsg.Set_U32_BE (B, 2, 16#01020304#);
      Imsg.Rewind (B);
      Imsg.Skip (B, 2);
      Imsg.Get_U32_BE (B, U32v);
      Pass ("buffer set_u32_be", U32v = 16#01020304#);
      Imsg.Free (B);

      --  16-bit and 64-bit little-endian set round-trips
      Imsg.Dynamic_Buffer (B, 0, 16);
      Imsg.Add_Zero (B, 3);
      Imsg.Set_U16_LE (B, 1, 16#ABCD#);
      Imsg.Rewind (B);
      Imsg.Skip (B, 1);
      Imsg.Get_U16_LE (B, U16);
      Pass ("buffer set_u16_le", U16 = 16#ABCD#);
      Imsg.Free (B);
      Imsg.Dynamic_Buffer (B, 0, 16);
      Imsg.Add_Zero (B, 8);
      Imsg.Set_U64_LE (B, 0, 16#0102030405060708#);
      Imsg.Rewind (B);
      Imsg.Get_U64_LE (B, U64v);
      Pass ("buffer set_u64_le", U64v = 16#0102030405060708#);
      Imsg.Free (B);

      --  truncate down and back up
      Imsg.Dynamic_Buffer (B, 0, 64);
      Imsg.Add_String (B, "abcde");
      Imsg.Truncate (B, 3);
      Pass ("buffer truncate down", Imsg.Size (B) = 3);
      Imsg.Truncate (B, 6);
      Pass ("buffer truncate up", Imsg.Size (B) = 6);
      Imsg.Free (B);

      --  append one buffer's unread bytes into another (ibuf_add_ibuf)
      Imsg.Dynamic_Buffer (B, 0, 16);
      declare
         B2 : Imsg.Buffer;
      begin
         Imsg.Dynamic_Buffer (B2, 0, 16);
         Imsg.Add_U8 (B2, 16#11#);
         Imsg.Add_U8 (B2, 16#22#);
         Imsg.Add_Ibuf (B, B2);
         Pass ("buffer add_ibuf", Imsg.Data (B) = [16#11#, 16#22#]);
         Imsg.Free (B2);
      end;
      Imsg.Free (B);

      --  fixed-width NUL-padded string (ibuf_add_strbuf)
      Imsg.Dynamic_Buffer (B, 0, 16);
      Imsg.Add_Strbuf (B, "hi", 5);
      Pass ("buffer add_strbuf",
        Imsg.Data (B) = [16#68#, 16#69#, 0, 0, 0]);
      Imsg.Free (B);

      --  wrap a payload as a buffer for reading (ibuf_from_buffer)
      declare
         B3 : Imsg.Buffer;
      begin
         Imsg.From_Buffer (B3, [16#AA#, 16#BB#]);
         Imsg.Get_U8 (B3, U8);
         Pass ("buffer from_buffer", U8 = 16#AA# and Imsg.Size (B3) = 1);
         Imsg.Free (B3);
      end;

      --  extract unread bytes into a fresh buffer (ibuf_get_ibuf)
      Imsg.Dynamic_Buffer (B, 0, 16);
      Imsg.Add_U8 (B, 16#01#);
      Imsg.Add_U8 (B, 16#02#);
      Imsg.Add_U8 (B, 16#03#);
      Imsg.Rewind (B);
      declare
         B4 : Imsg.Buffer;
      begin
         Imsg.Get_Ibuf (B, 2, B4);
         Pass ("buffer get_ibuf", Imsg.Data (B4) = [16#01#, 16#02#]);
         Pass ("buffer get_ibuf advance", Imsg.Size (B) = 1);
         Imsg.Free (B4);
      end;
      Imsg.Free (B);

      --  a fixed buffer can not grow
      Imsg.Open_Buffer (B, 4);
      declare
         Overflowed : Boolean := False;
      begin
         begin
            Imsg.Add_Zero (B, 5);
         exception
            when Constraint_Error => Overflowed := True;
         end;
         Pass ("buffer fixed overflow", Overflowed);
      end;
      Imsg.Free (B);

      --  a dynamic buffer can not exceed its max
      Imsg.Dynamic_Buffer (B, 0, 4);
      declare
         Overflowed : Boolean := False;
      begin
         begin
            Imsg.Add_Zero (B, 5);
         exception
            when Constraint_Error => Overflowed := True;
         end;
         Pass ("buffer dynamic overflow", Overflowed);
      end;
      Imsg.Free (B);
   end Check_Buffer;

   procedure Check_Connection is
      A, B : GNAT.Sockets.Socket_Type;
      Ca   : Imsg.Connection;
      Cb   : Imsg.Connection;
   begin
      GNAT.Sockets.Create_Socket_Pair (A, B);
      Imsg.Initialize (Ca, A);
      Imsg.Initialize (Cb, B);

      --  one-shot compose + round-trip
      Imsg.Compose (Ca, 7, 0, 0, -1, [16#01#, 16#02#, 16#03#]);
      Pass ("connection queue length", Imsg.Queue_Length (Ca) = 1);
      Imsg.Flush (Ca);
      Imsg.Read (Cb);
      declare
         R : constant Imsg.Received := Imsg.Get (Cb);
         F : constant Imsg.Frame := Imsg.Decode (R.Data);
      begin
         Pass ("connection kind", F.Kind = 7);
         Pass ("connection payload", F.Data = [16#01#, 16#02#, 16#03#]);
         Pass ("connection no fd", R.Fd = -1);
      end;

      --  compose_buffer + add + close + round-trip
      declare
         Mb : Imsg.Buffer_Access;
      begin
         Mb := Imsg.Compose_Buffer (Ca, 11, 4, 0, 0);
         Imsg.Add_U32_LE (Mb.all, 16#DEADBEEF#);
         Imsg.Close (Ca, Mb);
         Imsg.Flush (Ca);
         Imsg.Read (Cb);
         declare
            R : constant Imsg.Received := Imsg.Get (Cb);
            F : constant Imsg.Frame := Imsg.Decode (R.Data);
         begin
            Pass ("connection compose_buffer kind", F.Kind = 11);
            Pass ("connection compose_buffer payload",
              F.Data = [16#EF#, 16#BE#, 16#AD#, 16#DE#]);
         end;
      end;

      --  two messages in one flush
      Imsg.Compose (Ca, 20, 0, 0, -1, [16#AA#]);
      Imsg.Compose (Ca, 21, 0, 0, -1, [16#BB#]);
      Imsg.Flush (Ca);
      Imsg.Read (Cb);
      declare
         R1 : constant Imsg.Received := Imsg.Get (Cb);
         R2 : constant Imsg.Received := Imsg.Get (Cb);
         F1 : constant Imsg.Frame := Imsg.Decode (R1.Data);
         F2 : constant Imsg.Frame := Imsg.Decode (R2.Data);
      begin
         Pass ("connection multi first", F1.Kind = 20);
         Pass ("connection multi second", F2.Kind = 21);
      end;

      --  get raises Not_Complete on an empty read queue
      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               R3 : constant Imsg.Received := Imsg.Get (Cb);
               pragma Unreferenced (R3);
            begin
               null;
            end;
         exception
            when Imsg.Not_Complete => Raised := True;
         end;
         Pass ("connection not_complete", Raised);
      end;

      --  descriptor passing through the connection
      declare
         use Ada.Streams;
         X, Y : GNAT.Sockets.Socket_Type;
      begin
         GNAT.Sockets.Create_Socket_Pair (X, Y);
         Imsg.Compose (Ca, 9, 0, 0, GNAT.Sockets.To_C (X), [16#42#]);
         Imsg.Flush (Ca);   --  sends the fd and closes X here
         Imsg.Read (Cb);
         declare
            R : constant Imsg.Received := Imsg.Get (Cb);
         begin
            Pass ("connection fd received", R.Fd >= 0);
            if R.Fd >= 0 then
               declare
                  Rfds : GNAT.Sockets.Socket_Type :=
                    GNAT.Sockets.To_Ada (R.Fd);
                  Got  : Stream_Element_Array (1 .. 1);
                  Last : Stream_Element_Offset;
               begin
                  GNAT.Sockets.Send_Socket (Y, [16#5A#], Last);
                  GNAT.Sockets.Receive_Socket (Rfds, Got, Last);
                  Pass ("connection fd live",
                    Last >= Got'First and then Got (1) = 16#5A#);
                  GNAT.Sockets.Close_Socket (Rfds);
               end;
            end if;
         end;
         GNAT.Sockets.Close_Socket (Y);
      end;

      --  forward a received message onto another connection (imsg_forward)
      declare
         C2, D2 : GNAT.Sockets.Socket_Type;
         Cc     : Imsg.Connection;
         Cd     : Imsg.Connection;
      begin
         GNAT.Sockets.Create_Socket_Pair (C2, D2);
         Imsg.Initialize (Cc, C2);
         Imsg.Initialize (Cd, D2);
         Imsg.Compose (Ca, 30, 0, 0, -1, [16#55#, 16#66#]);
         Imsg.Flush (Ca);
         Imsg.Read (Cb);
         Imsg.Forward (Cc, Imsg.Get (Cb));
         Imsg.Flush (Cc);
         Imsg.Read (Cd);
         declare
            R : constant Imsg.Received := Imsg.Get (Cd);
            F : constant Imsg.Frame := Imsg.Decode (R.Data);
         begin
            Pass ("connection forward kind", F.Kind = 30);
            Pass ("connection forward payload", F.Data = [16#55#, 16#66#]);
         end;
         GNAT.Sockets.Close_Socket (C2);
         GNAT.Sockets.Close_Socket (D2);
      end;

      --  compose from several parts (imsg_composev)
      declare
         Parts : Imsg.Payload_Vectors.Vector;
      begin
         Imsg.Payload_Vectors.Append (Parts, Imsg.Payload'([16#AA#]));
         Imsg.Payload_Vectors.Append (Parts, Imsg.Payload'([16#BB#, 16#CC#]));
         Imsg.Compose_V (Ca, 40, 0, 0, -1, Parts);
         Imsg.Flush (Ca);
         Imsg.Read (Cb);
         declare
            R : constant Imsg.Received := Imsg.Get (Cb);
            F : constant Imsg.Frame := Imsg.Decode (R.Data);
         begin
            Pass ("connection compose_v", F.Data = [16#AA#, 16#BB#, 16#CC#]);
         end;
      end;

      GNAT.Sockets.Close_Socket (A);
      GNAT.Sockets.Close_Socket (B);
   end Check_Connection;

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
   Check_Closed_Peer;
   Check_Buffer;
   Check_Connection;

   Ada.Text_IO.Put_Line
     ("checks: " & Natural'Image (Checks) &
      ", failures: " & Natural'Image (Failures));
   if Failures = 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Imsg_Check;
