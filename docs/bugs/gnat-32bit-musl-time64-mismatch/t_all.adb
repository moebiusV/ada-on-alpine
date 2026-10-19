--  Self-checking test of the GNAT runtime's time handling and, where the
--  runtime has it, the shared Unbounded strings.  Prints PASS/FAIL per check
--  and exits with status 1 if any failed.
with Ada.Calendar;
with Ada.Command_Line;
with Ada.Execution_Time;
with Ada.Real_Time;          use Ada.Real_Time;
with Ada.Streams;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;
with Ada.Text_IO;            use Ada.Text_IO;
with GNAT.Sockets;           use GNAT.Sockets;

procedure T_All is

   Failures : Natural := 0;

   procedure Check (Name : String; OK : Boolean; Detail : String := "") is
   begin
      if OK then
         Put_Line ("PASS " & Name & "  [" & Detail & "]");
      else
         Put_Line ("FAIL " & Name & "  [" & Detail & "]");
         Failures := Failures + 1;
      end if;
   end Check;

   function Secs (Span : Time_Span) return Duration is
   begin
      return To_Duration (Span);
   end Secs;

   function Img (D : Duration) return String is
      S : constant String := Duration'Image (D);
   begin
      return S;
   end Img;

   --  Leave a recognisable pattern in the stack below the caller
   procedure Pollute (Depth : Natural) is
      Junk : array (1 .. 512) of Integer := (others => -1);
   begin
      Junk (Junk'First + Depth mod 512) := Depth;
      if Depth > 0 then
         Pollute (Depth - 1);
      end if;
      if Junk (1) = 42 then
         Put ("");
      end if;
   end Pollute;

   --  Never accepts Go, so a timed call of Go always times out
   task type Waiter is
      entry Go;
      entry Quit;
   end Waiter;

   task body Waiter is
   begin
      accept Quit;
   end Waiter;

begin
   ----------------------------------------------------------------------
   --  Clocks
   ----------------------------------------------------------------------
   declare
      T0 : constant Time := Clock;
      S  : Seconds_Count;
      F  : Time_Span;
      T1 : Time;
   begin
      Split (T0, S, F);
      Check ("Real_Time.Clock is not negative", S >= 0,
             "seconds =" & Seconds_Count'Image (S));
      T1 := Clock;
      Check ("Real_Time.Clock does not go backwards", T1 >= T0);
   end;

   declare
      Y : constant Ada.Calendar.Year_Number :=
        Ada.Calendar.Year (Ada.Calendar.Clock);
   begin
      Check ("Calendar.Clock year is the current one",
             Y >= 2024 and then Y <= 2100,
             "year =" & Ada.Calendar.Year_Number'Image (Y));
   end;

   ----------------------------------------------------------------------
   --  Delays
   ----------------------------------------------------------------------
   declare
      T0 : constant Time := Clock;
      E  : Duration;
   begin
      delay 0.2;
      E := Secs (Clock - T0);
      Check ("delay 0.2 (Real_Time)", E >= 0.19 and then E < 0.8, Img (E));
   end;

   declare
      use Ada.Calendar;
      T0 : constant Ada.Calendar.Time := Ada.Calendar.Clock;
      E  : Duration;
   begin
      delay 0.2;
      E := Ada.Calendar.Clock - T0;
      Check ("delay 0.2 (Calendar)", E >= 0.19 and then E < 0.8, Img (E));
   end;

   declare
      T0 : constant Time := Clock;
      E  : Duration;
   begin
      delay until T0 + Milliseconds (250);
      E := Secs (Clock - T0);
      Check ("delay until +0.25", E >= 0.24 and then E < 0.8, Img (E));
   end;

   ----------------------------------------------------------------------
   --  Timed waits in the tasking runtime (pthread_cond_timedwait)
   ----------------------------------------------------------------------
   declare
      W  : Waiter;
      T0 : Time;
      E  : Duration;
      Timed_Out : Boolean := False;
   begin
      T0 := Clock;
      select
         W.Go;
      or
         delay 0.3;
         Timed_Out := True;
      end select;
      E := Secs (Clock - T0);
      Check ("timed entry call times out", Timed_Out
             and then E >= 0.29 and then E < 0.9, Img (E));
      W.Quit;
   end;

   ----------------------------------------------------------------------
   --  The same after garbage was left in the stack below (the 16-byte
   --  timespec has 4 bytes of padding that Ada never initializes)
   ----------------------------------------------------------------------
   declare
      Bad : Natural := 0;
      Worst : Duration := 0.0;
   begin
      for I in 1 .. 40 loop
         Pollute (60);
         declare
            T0 : constant Time := Clock;
            E  : Duration;
         begin
            delay 0.02;
            E := Secs (Clock - T0);
            if E < 0.019 or else E > 0.7 then
               Bad := Bad + 1;
            end if;
            if E > Worst then
               Worst := E;
            end if;
         end;
      end loop;
      Check ("40 short delays after polluting the stack", Bad = 0,
             "bad =" & Natural'Image (Bad) & ", worst " & Img (Worst));
   end;

   declare
      Bad : Natural := 0;
   begin
      for I in 1 .. 10 loop
         Pollute (60);
         declare
            W : Waiter;
            T0 : constant Time := Clock;
            E  : Duration;
            Timed_Out : Boolean := False;
         begin
            select
               W.Go;
            or
               delay 0.05;
               Timed_Out := True;
            end select;
            E := Secs (Clock - T0);
            if not Timed_Out or else E < 0.049 or else E > 0.7 then
               Bad := Bad + 1;
            end if;
            W.Quit;
         end;
      end loop;
      Check ("10 timed entry calls after polluting the stack", Bad = 0,
             "bad =" & Natural'Image (Bad));
   end;

   ----------------------------------------------------------------------
   --  Sockets: select with a timeout (C_Select) and SO_RCVTIMEO (timeval)
   ----------------------------------------------------------------------
   declare
      Sel   : Selector_Type;
      RSet, WSet : Socket_Set_Type;
      Status : Selector_Status;
      T0    : Time;
      E     : Duration;
   begin
      Create_Selector (Sel);
      Empty (RSet);
      Empty (WSet);
      T0 := Clock;
      Check_Selector (Sel, RSet, WSet, Status, 0.3);
      E := Secs (Clock - T0);
      Check ("Check_Selector times out", Status = Expired
             and then E >= 0.29 and then E < 0.9,
             Selector_Status'Image (Status) & " " & Img (E));
      Close_Selector (Sel);
   end;

   declare
      S    : Socket_Type;
      Addr : constant Sock_Addr_Type :=
        (Family => Family_Inet, Addr => Inet_Addr ("127.0.0.1"), Port => 0);
      Data : Ada.Streams.Stream_Element_Array (1 .. 16);
      Last : Ada.Streams.Stream_Element_Offset;
      From : Sock_Addr_Type;
      T0   : Time;
      E    : Duration;
      Got_Error : Boolean := False;
   begin
      Create_Socket (S, Family_Inet, Socket_Datagram);
      Bind_Socket (S, Addr);
      Set_Socket_Option (S, Socket_Level, (Receive_Timeout, 0.3));
      T0 := Clock;
      begin
         Receive_Socket (S, Data, Last, From);
      exception
         when Socket_Error =>
            Got_Error := True;
      end;
      E := Secs (Clock - T0);
      Check ("Receive_Timeout (SO_RCVTIMEO) expires", Got_Error
             and then E >= 0.25 and then E < 0.9, Img (E));
      Close_Socket (S);
   end;

   ----------------------------------------------------------------------
   --  Ada.Execution_Time (needs a-exetim__posix)
   ----------------------------------------------------------------------
   declare
      use Ada.Execution_Time;
      C0 : constant CPU_Time := Clock;
      T0 : constant Time := Ada.Real_Time.Clock;
      X  : Long_Long_Integer := 0;
      D  : Time_Span;
   begin
      while Ada.Real_Time.Clock - T0 < Milliseconds (300) loop
         X := X + 1;
      end loop;
      D := Clock - C0;
      Check ("Execution_Time.Clock advances while computing",
             D > Milliseconds (50) and then D < Milliseconds (1500),
             Img (Secs (D)) & " (x=" & Long_Long_Integer'Image (X mod 10) & ")");
   end;

   ----------------------------------------------------------------------
   --  Unbounded strings (shared implementation on s390x/riscv64 now)
   ----------------------------------------------------------------------
   declare
      A : Unbounded_String := To_Unbounded_String ("shared");
      B : constant Unbounded_String := A;
      C : Unbounded_String := A;
   begin
      Append (A, " strings");
      Append (C, "!");
      Check ("Unbounded_String copies keep their own contents",
             To_String (A) = "shared strings" and then To_String (B) = "shared"
             and then To_String (C) = "shared!", To_String (A));
   end;

   New_Line;
   if Failures = 0 then
      Put_Line ("ALL PASS");
   else
      Put_Line ("FAILURES:" & Natural'Image (Failures));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end T_All;
