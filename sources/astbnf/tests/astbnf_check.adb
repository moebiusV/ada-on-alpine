pragma Ada_2022;

with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with ASTBNF;
use type ASTBNF.Element_Kind;
with ASTBNF_Ada;
with ASTBNF_C;

--  Check the parser and both emitters against two schema files passed on the
--  command line.  Usage: astbnf_check <server.astbnf> <hbnf.astbnf>
--  The first is the small server example, which drives the C/Ada emitters;
--  the second is the hbnf config grammar, checked at the parse level (its
--  entry/block rules are mutually recursive, which the declaration-only
--  emitters reject as a cyclic reference).
procedure ASTBNF_Check is

   use Ada.Strings.Unbounded;

   Failures : Natural := 0;
   Checks   : Natural := 0;

   procedure Check (Name : String; Cond : Boolean) is
   begin
      Checks := Checks + 1;
      if Cond then
         Ada.Text_IO.Put_Line ("ok: " & Name);
      else
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
      end if;
   end Check;

   function Has (Hay, Needle : String) return Boolean is
   begin
      if Needle'Length = 0 then
         return True;
      end if;
      for I in Hay'First .. Hay'Last - Needle'Length + 1 loop
         if Hay (I .. I + Needle'Length - 1) = Needle then
            return True;
         end if;
      end loop;
      return False;
   end Has;

   function Read_File (Path : String) return String is
      F   : Ada.Text_IO.File_Type;
      Buf : Unbounded_String;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (F) loop
         Append (Buf, Ada.Text_IO.Get_Line (F));
         if not Ada.Text_IO.End_Of_File (F) then
            Append (Buf, ASCII.LF);
         end if;
      end loop;
      Ada.Text_IO.Close (F);
      return To_String (Buf);
   end Read_File;

   function Find_Rule
     (Rules : ASTBNF.Rule_Vectors.Vector; Name : String) return Natural is
   begin
      for I in 1 .. Natural (Rules.Length) loop
         if To_String (Rules (I).Name) = Name then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Rule;

   procedure Check_Server (Path : String) is
      Rules    : constant ASTBNF.Rule_Vectors.Vector :=
        ASTBNF.Parse (Read_File (Path));
      C_Text   : constant String := ASTBNF_C.Emit (Rules);
      Ada_Text : constant String := ASTBNF_Ada.Emit (Rules, "Server_Schema");
   begin
      Check ("13 rules", Natural (Rules.Length) = 13);
      Check ("first rule server", To_String (Rules (1).Name) = "server");

      Check ("C enum", Has (C_Text, "DIRECTION_IN"));
      Check ("C struct", Has (C_Text, "typedef struct"));
      Check ("C scalar", Has (C_Text, "typedef const char * name_t;"));
      Check ("C comment", Has (C_Text, "/* host name"));

      Check ("Ada enum", Has (Ada_Text, "Direction_In"));
      Check ("Ada record", Has (Ada_Text, "type Server_Type is record"));
      Check ("Ada subtype",
             Has (Ada_Text, "subtype Port_Type is Unsigned_16"));
      Check ("Ada comment", Has (Ada_Text, "-- host name"));
   end Check_Server;

   procedure Check_Hbnf (Path : String) is
      Rules : constant ASTBNF.Rule_Vectors.Vector :=
        ASTBNF.Parse (Read_File (Path));
      I     : Natural;
   begin
      Check ("hbnf 7 rules", Natural (Rules.Length) = 7);

      --  config = *entry : a repeated reference (a list).
      I := Find_Rule (Rules, "config");
      Check ("config is a list",
             I /= 0 and then Natural (Rules (I).Pattern.Length) = 1
               and then Rules (I).Pattern (1).Kind = ASTBNF.Name
               and then Rules (I).Pattern (1).Min = 0
               and then Rules (I).Pattern (1).Max = -1
               and then To_String (Rules (I).Pattern (1).Name) = "entry");

      --  entry = statement / block : an alternation of two references.
      I := Find_Rule (Rules, "entry");
      Check ("entry is an alternation",
             I /= 0 and then Natural (Rules (I).Pattern.Length) = 3
               and then Rules (I).Pattern (1).Kind = ASTBNF.Name
               and then Rules (I).Pattern (2).Kind = ASTBNF.Alt
               and then Rules (I).Pattern (3).Kind = ASTBNF.Name
               and then To_String (Rules (I).Pattern (1).Name) = "statement"
               and then To_String (Rules (I).Pattern (3).Name) = "block");

      --  statement = name *arg (";" / "\n") : keyword + args, ended by a
      --  semicolon or a newline token.
      I := Find_Rule (Rules, "statement");
      Check ("statement ends in ; or newline",
             I /= 0 and then Natural (Rules (I).Pattern.Length) = 3
               and then Rules (I).Pattern (3).Kind = ASTBNF.Group
               and then Natural (Rules (I).Pattern (3).Items.Length) = 3
               and then Rules (I).Pattern (3).Items (1).Kind = ASTBNF.Literal
               and then To_String (Rules (I).Pattern (3).Items (1).Lit) = ";"
               and then Rules (I).Pattern (3).Items (2).Kind = ASTBNF.Alt
               and then Rules (I).Pattern (3).Items (3).Kind = ASTBNF.Literal
               and then To_String (Rules (I).Pattern (3).Items (3).Lit) =
                 ("" & ASCII.LF));

      --  block = name [qualifier] "{" *entry "}" : keyword, optional
      --  qualifier (a bracket group), then a repeated child list.
      I := Find_Rule (Rules, "block");
      Check ("block nests entries",
             I /= 0 and then Natural (Rules (I).Pattern.Length) = 5
               and then Rules (I).Pattern (2).Kind = ASTBNF.Group
               and then Rules (I).Pattern (2).Min = 0
               and then Rules (I).Pattern (2).Max = 1
               and then Rules (I).Pattern (3).Kind = ASTBNF.Literal
               and then To_String (Rules (I).Pattern (3).Lit) = "{"
               and then Rules (I).Pattern (4).Kind = ASTBNF.Name
               and then Rules (I).Pattern (4).Min = 0
               and then Rules (I).Pattern (4).Max = -1
               and then To_String (Rules (I).Pattern (4).Name) = "entry");

      --  name = atom : a bare-token scalar.
      I := Find_Rule (Rules, "name");
      Check ("name is an atom",
             I /= 0 and then Natural (Rules (I).Pattern.Length) = 1
               and then Rules (I).Pattern (1).Kind = ASTBNF.Name
               and then To_String (Rules (I).Pattern (1).Name) = "atom");

      --  qualifier = str / atom ; arg = atom / str / int / dec.
      I := Find_Rule (Rules, "qualifier");
      Check ("qualifier alternates str/atom",
             I /= 0 and then Natural (Rules (I).Pattern.Length) = 3
               and then Rules (I).Pattern (2).Kind = ASTBNF.Alt);
      I := Find_Rule (Rules, "arg");
      Check ("arg alternates atom/str/int/dec",
             I /= 0 and then Natural (Rules (I).Pattern.Length) = 7);

      --  The emitters break the entry/block mutual recursion: forward
      --  declarations (C) and access types (Ada) at the repeated member.
      declare
         C_Text : constant String := ASTBNF_C.Emit (Rules);
         A_Text : constant String := ASTBNF_Ada.Emit (Rules, "Hbnf_Schema");
      begin
         Check ("hbnf C forward decl",
                Has (C_Text, "typedef struct entry entry_t;"));
         Check ("hbnf C list member",
                Has (C_Text, "struct { entry_t *items; size_t n; } entry;"));
         Check ("hbnf Ada access type",
                Has (A_Text, "type Entry_Access is access Entry_Type;"));
         Check ("hbnf Ada list field",
                Has (A_Text, "Entry_F : Block_Entry_Vectors.Vector;"));
      end;
   end Check_Hbnf;

begin
   Check_Server (Ada.Command_Line.Argument (1));
   Check_Hbnf (Ada.Command_Line.Argument (2));

   Ada.Text_IO.Put_Line
     ("checks: " & Natural'Image (Checks) &
      ", failures: " & Natural'Image (Failures));
   if Failures = 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end ASTBNF_Check;
