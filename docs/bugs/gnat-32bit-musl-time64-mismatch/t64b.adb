with Ada.Text_IO;        use Ada.Text_IO;
with Ada.Calendar;
with Ada.Real_Time;      use Ada.Real_Time;
with Ada.Execution_Time;
with GNAT.Sockets;       use GNAT.Sockets;

procedure T64b is
   Failures : Natural := 0;

   procedure Check (Name : String; Ok : Boolean) is
   begin
      Put_Line ((if Ok then "ok   " else "FAIL ") & Name);
      if not Ok then
         Failures := Failures + 1;
      end if;
   end Check;

   function Secs (D : Time_Span) return Duration is (To_Duration (D));

   task Busy is
      entry Go;
   end Busy;

   task body Busy is
   begin
      delay 2.0;
      accept Go;
   end Busy;

   Year   : Integer;
   T0, T1 : Time;
   Sel    : Selector_Type;
   R, W   : Socket_Set_Type;
   Status : Selector_Status;
   Secs_CT, Dummy : Ada.Execution_Time.CPU_Time;
begin
   Year := Ada.Calendar.Year (Ada.Calendar.Clock);
   Check ("Calendar year 2025..2100 (got" & Integer'Image (Year) & ")",
          Year in 2025 .. 2100);

   T0 := Clock;
   delay 0.3;
   T1 := Clock;
   Check ("delay 0.3 -> Real_Time elapsed" & Duration'Image (Secs (T1 - T0)),
          Secs (T1 - T0) in 0.29 .. 0.8);

   --  A timed entry call: waits in pthread_cond_timedwait.
   T0 := Clock;
   select
      Busy.Go;
      Check ("timed entry call was not accepted", False);
   or
      delay 0.3;
   end select;
   T1 := Clock;
   Check ("timed entry call timeout ->" & Duration'Image (Secs (T1 - T0)),
          Secs (T1 - T0) in 0.29 .. 0.8);
   abort Busy;

   Dummy := Ada.Execution_Time.Clock;
   Secs_CT := Ada.Execution_Time.Clock;
   Check ("Execution_Time.Clock is monotonic", Ada.Execution_Time."<=" (Dummy, Secs_CT));

   --  GNAT.Sockets: select() with a timeout.
   Create_Selector (Sel);
   Empty (R);
   Empty (W);
   T0 := Clock;
   Check_Selector (Sel, R, W, Status, Timeout => 0.3);
   T1 := Clock;
   Check ("Check_Selector timeout 0.3 ->" & Duration'Image (Secs (T1 - T0))
          & " status " & Selector_Status'Image (Status),
          Status = Expired and then Secs (T1 - T0) in 0.29 .. 0.8);
   Close_Selector (Sel);

   if Failures = 0 then
      Put_Line ("ALL OK");
   else
      Put_Line (Natural'Image (Failures) & " FAILED");
   end if;
end T64b;
