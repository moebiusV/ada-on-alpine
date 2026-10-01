pragma Ada_2022;

--  Smoke test for the Mustache package API: build a view, render, and check
--  the core behaviours (escaping, raw interpolation, sections, inverted
--  sections, dotted names, and the implicit iterator).  The full conformance
--  run is spec_check over the official spec fixtures.

with Mustache; use Mustache;
with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;

procedure Mustache_Check is

   Failures : Natural := 0;

   procedure Check (Label, Got, Want : String) is
   begin
      if Got = Want then
         Put_Line ("ok: " & Label);
      else
         Put_Line ("FAIL: " & Label);
         Put_Line ("  got:  [" & Got & "]");
         Put_Line ("  want: [" & Want & "]");
         Failures := Failures + 1;
      end if;
   end Check;

begin
   declare
      V : Context := View;
   begin
      Put (V, "forbidden", "& < >");
      Check ("escape", Render ("{{forbidden}}", V), "&amp; &lt; &gt;");
      Check ("raw triple", Render ("{{{forbidden}}}", V), "& < >");
      Check ("raw amp", Render ("{{&forbidden}}", V), "& < >");
      Check ("missing renders empty", Render ("{{nope}}", V), "");
   end;

   declare
      V : Context := View;
      L : constant Value_Access := New_List;
   begin
      Append (L, New_Scalar ("a"));
      Append (L, New_Scalar ("b"));
      Put (V, "items", L);
      Check ("each + dot", Render ("{{#items}}[{{.}}]{{/items}}", V),
             "[a][b]");
      Check ("inverted missing", Render ("{{^gone}}none{{/gone}}", V), "none");
   end;

   declare
      V     : Context := View;
      Inner : constant Value_Access := New_Map;
   begin
      Insert (Inner, "name", New_Scalar ("Joe"));
      Put (V, "person", Inner);
      Check ("dotted name", Render ("{{person.name}}", V), "Joe");
   end;

   if Failures = 0 then
      Put_Line ("checks: all passed");
   else
      Put_Line ("checks:" & Natural'Image (Failures) & " failed");
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Mustache_Check;
