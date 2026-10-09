with Ada.Text_IO; use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Calendar;

procedure T64 is
   T0 : constant Time := Clock;
   S  : Seconds_Count;
   F  : Time_Span;
begin
   Split (T0, S, F);
   Put_Line ("Real_Time.Clock seconds =" & Seconds_Count'Image (S));
   Put_Line ("fraction (s)            =" & Duration'Image (To_Duration (F)));
   delay 0.05;
   Put_Line ("after delay 0.05, elapsed ="
             & Duration'Image (To_Duration (Clock - T0)));
   Put_Line ("Calendar year           ="
             & Ada.Calendar.Year_Number'Image
                 (Ada.Calendar.Year (Ada.Calendar.Clock)));
end T64;
