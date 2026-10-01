pragma Ada_2022;

--  Mustache conformance runner: run the core spec fixtures (the *.json files
--  that do not begin with "~") through the engine and compare each test's
--  output to its expected output.  Usage: spec_check <spec-dir>.

with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Json;
with Mustache;

procedure Spec_Check is

   use Ada.Strings.Unbounded;
   use Ada.Text_IO;
   use Mustache;
   use type Mustache.Value_Maps.Cursor;

   Total    : Natural := 0;
   Failures : Natural := 0;

   function Field (V : Value_Access; Key : String) return Value_Access is
   begin
      if V = null or else V.Kind /= Map then
         return null;
      end if;
      declare
         C : constant Value_Maps.Cursor := V.Fields.Find (Key);
      begin
         if C = Value_Maps.No_Element then
            return null;
         end if;
         return Value_Maps.Element (C);
      end;
   end Field;

   function Str (V : Value_Access) return String is
   begin
      if V = null or else V.Kind /= Scalar then
         return "";
      end if;
      return To_String (V.Text);
   end Str;

   procedure Run_File (Path : String) is
      F   : Ada.Text_IO.File_Type;
      Buf : Unbounded_String;
   begin
      Open (F, In_File, Path);
      while not End_Of_File (F) loop
         Append (Buf, Get_Line (F));
         Append (Buf, ASCII.LF);
      end loop;
      Close (F);

      declare
         Root  : constant Value_Access := Json.Parse (To_String (Buf));
         Tests : constant Value_Access := Field (Root, "tests");
      begin
         if Tests = null or else Tests.Kind /= List then
            return;
         end if;
         for T of Tests.Items loop
            Total := Total + 1;
            declare
               Name : constant String      := Str (Field (T, "name"));
               Data : constant Value_Access := Field (T, "data");
               Tmpl : constant String      := Str (Field (T, "template"));
               Want : constant String      := Str (Field (T, "expected"));
               Part : constant Value_Access := Field (T, "partials");
               View : Context;
            begin
               Reset;
               if Part /= null and then Part.Kind = Map then
                  declare
                     C : Value_Maps.Cursor := Part.Fields.First;
                  begin
                     while C /= Value_Maps.No_Element loop
                        Define (Value_Maps.Key (C),
                                Str (Value_Maps.Element (C)));
                        Value_Maps.Next (C);
                     end loop;
                  end;
               end if;
               if Data = null then
                  View.Scopes.Append (New_Map);
               else
                  View.Scopes.Append (Data);
               end if;

               declare
                  Got : constant String := Render (Tmpl, View);
               begin
                  if Got = Want then
                     Put_Line ("ok: " & Name);
                  else
                     Put_Line ("FAIL: " & Name);
                     Put_Line ("  got:  [" & Got & "]");
                     Put_Line ("  want: [" & Want & "]");
                     Failures := Failures + 1;
                  end if;
               exception
                  when Template_Error =>
                     Put_Line ("ERROR: " & Name);
                     Failures := Failures + 1;
               end;
            end;
         end loop;
      end;
   exception
      when E : others =>
         Put_Line ("ERROR: " & Path & ": "
                   & Ada.Exceptions.Exception_Name (E) & ": "
                   & Ada.Exceptions.Exception_Message (E));
         Failures := Failures + 1;
   end Run_File;

   Dir : constant String := Ada.Command_Line.Argument (1);
   Filter : constant Ada.Directories.Filter_Type :=
     [Ada.Directories.Ordinary_File => True, others => False];

   procedure Visit (E : Ada.Directories.Directory_Entry_Type) is
      Name : constant String := Ada.Directories.Simple_Name (E);
   begin
      if Name'Length > 5
        and then Name (Name'Last - 4 .. Name'Last) = ".json"
        and then Name (Name'First) /= '~'
      then
         Put_Line ("== " & Name);
         Run_File (Ada.Directories.Full_Name (E));
      end if;
   end Visit;

begin
   Ada.Directories.Search (Dir, "*.json", Filter, Visit'Access);
   Put_Line ("checks:" & Natural'Image (Total)
             & " total," & Natural'Image (Failures) & " failed");
   if Failures > 0 then
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Spec_Check;
