pragma Ada_2022;

--  Conformance driver for the Mustache package: render the fixture templates
--  against a context and check each against its expected output, then check
--  the error cases (an unfilled {{var}}, a {{#each}} over a non-list, and an
--  unterminated section) each raise Template_Error.
--
--  Usage: mustache_check <template-dir>

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

   Root     : constant Value_Access := New_Map;
   Fields   : constant Value_Access := New_List;
   Keywords : constant Value_Access := New_List;
   Items    : constant Value_Access := New_List;
   Ctx      : Context;

   procedure Expect_Error (Label, Source : String) is
   begin
      declare
         S : constant String := Render_Text (Source, Ctx);
      begin
         Put_Line ("FAIL: " & Label & " (rendered without error)");
         Put_Line ("  got: [" & S & "]");
         Failures := Failures + 1;
      end;
   exception
      when Template_Error =>
         Put_Line ("ok: " & Label);
   end Expect_Error;

begin
   Load (Ada.Command_Line.Argument (1));

   declare
      F1 : constant Value_Access := New_Map;
      F2 : constant Value_Access := New_Map;
   begin
      Insert (F1, "type", New_Scalar ("int"));
      Insert (F1, "fname", New_Scalar ("x"));
      Insert (F2, "type", New_Scalar ("char*"));
      Insert (F2, "fname", New_Scalar ("y"));
      Append (Fields, F1);
      Append (Fields, F2);
   end;
   Append (Keywords, New_Scalar ("alpha"));
   Append (Keywords, New_Scalar ("beta"));
   Insert (Root, "name", New_Scalar ("foo_t"));
   Insert (Root, "fields", Fields);
   Insert (Root, "keywords", Keywords);
   Insert (Root, "items", Items);
   Ctx := New_Context (Root);

   Check ("interp + each over maps", Render ("struct", Ctx),
          "struct foo_t { int x; char* y; };");
   Check ("each over scalars + dot", Render ("kw", Ctx), "[alpha][beta]");
   Check ("inverted (empty list)", Render ("inv", Ctx), "none");
   Check ("partial", Render ("outer", Ctx),
          "struct foo_t { int x; char* y; };");
   Check ("render_text", Render_Text ("{{name}}", Ctx), "foo_t");

   Expect_Error ("unfilled {{var}}", "{{missing}}");
   Expect_Error ("non-scalar {{var}}", "{{fields}}");
   Expect_Error ("{{#each}} over a non-list", "{{#each name}}{{.}}{{/each}}");
   Expect_Error ("unterminated section", "{{#each fields}}{{type}}");

   if Failures = 0 then
      Put_Line ("checks: all passed");
   else
      Put_Line ("checks:" & Natural'Image (Failures) & " failed");
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Mustache_Check;
