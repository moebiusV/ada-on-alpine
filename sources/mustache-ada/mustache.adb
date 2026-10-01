pragma Ada_2022;

with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Mustache is

   use Ada.Strings.Unbounded;

   package Text_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (String, Unbounded_String);

   use type Text_Maps.Cursor;
   use type Value_Maps.Cursor;

   Store : Text_Maps.Map;

   --  =====================================================================
   --  Loading and defining templates.
   --  =====================================================================

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

   procedure Load (Dir : String) is
      Filter : constant Ada.Directories.Filter_Type :=
        [Ada.Directories.Ordinary_File => True, others => False];

      procedure Visit (Dir_Entry : Ada.Directories.Directory_Entry_Type) is
         Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
      begin
         if Name'Length > 5
           and then Name (Name'Last - 4 .. Name'Last) = ".tmpl"
         then
            Store.Include
              (Name (Name'First .. Name'Last - 5),
               To_Unbounded_String
                 (Read_File (Ada.Directories.Full_Name (Dir_Entry))));
         end if;
      end Visit;
   begin
      Ada.Directories.Search (Dir, "*.tmpl", Filter, Visit'Access);
   exception
      when Ada.Directories.Name_Error | Ada.Directories.Use_Error =>
         raise Template_Error with "no template directory `" & Dir & "`";
   end Load;

   procedure Define (Name : String; Source : String) is
   begin
      Store.Include (Name, To_Unbounded_String (Source));
   end Define;

   procedure Reset is
   begin
      Store.Clear;
   end Reset;

   function Get (Name : String) return String is
      C : constant Text_Maps.Cursor := Store.Find (Name);
   begin
      if C = Text_Maps.No_Element then
         raise Template_Error with "no template `" & Name & "` loaded";
      end if;
      return To_String (Text_Maps.Element (C));
   end Get;

   --  =====================================================================
   --  HTML escaping.
   --  =====================================================================

   function Escape (S : String) return String is
      Result : Unbounded_String;
   begin
      for C of S loop
         case C is
            when '&' => Append (Result, "&amp;");
            when '<' => Append (Result, "&lt;");
            when '>' => Append (Result, "&gt;");
            when '"' => Append (Result, "&quot;");
            when ''' => Append (Result, "&#39;");
            when others => Append (Result, C);
         end case;
      end loop;
      return To_String (Result);
   end Escape;

   --  =====================================================================
   --  Value builders.
   --  =====================================================================

   function New_Scalar (Text : String) return Value_Access is
     (new Value'(Kind => Scalar, Text => To_Unbounded_String (Text)));

   function New_List return Value_Access is
     (new Value'(Kind => List, Items => Value_Lists.Empty_Vector));

   function New_Map return Value_Access is
     (new Value'(Kind => Map, Fields => Value_Maps.Empty_Map));

   procedure Append (V : Value_Access; Item : Value_Access) is
   begin
      case V.Kind is
         when List =>
            V.Items.Append (Item);
         when others =>
            raise Template_Error with "append to a non-list value";
      end case;
   end Append;

   procedure Insert (V : Value_Access; Key : String; Item : Value_Access) is
   begin
      case V.Kind is
         when Map =>
            V.Fields.Include (Key, Item);
         when others =>
            raise Template_Error with "insert into a non-map value";
      end case;
   end Insert;

   --  =====================================================================
   --  Context.
   --  =====================================================================

   function View return Context is
      Ctx : Context;
   begin
      Ctx.Scopes.Append (New_Map);
      return Ctx;
   end View;

   procedure Put (Ctx : in out Context; Key : String; Value : String) is
      Top : constant Value_Access := Ctx.Scopes (Ctx.Scopes.Last_Index);
   begin
      Insert (Top, Key, New_Scalar (Value));
   end Put;

   procedure Put (Ctx : in out Context; Key : String; Value : Value_Access) is
      Top : constant Value_Access := Ctx.Scopes (Ctx.Scopes.Last_Index);
   begin
      Insert (Top, Key, Value);
   end Put;

   procedure Push (Ctx : in out Context; Scope : Value_Access) is
   begin
      Ctx.Scopes.Append (Scope);
   end Push;

   procedure Pop (Ctx : in out Context) is
   begin
      Ctx.Scopes.Delete_Last;
   end Pop;

   --  =====================================================================
   --  Tokenizer.
   --  =====================================================================

   type Token_Kind is
     (Text, Interp, Raw_Interp, Section_Open, Inverted_Open, Section_Close,
      Partial);

   type Token is record
      Kind   : Token_Kind;
      Name   : Unbounded_String;   --  Text: literal; else the tag body
      Indent : Unbounded_String;   --  Partial: the standalone indentation
   end record;

   package Token_Lists is new Ada.Containers.Vectors (Positive, Token);

   function Is_Blank (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT);

   function Is_Break (C : Character) return Boolean is
     (C = ASCII.LF or else C = ASCII.CR);

   function Trim (S : String) return String is
      F : Natural := S'First;
      L : Natural := S'Last;
   begin
      while F <= L and then Is_Blank (S (F)) loop
         F := F + 1;
      end loop;
      while L >= F and then Is_Blank (S (L)) loop
         L := L - 1;
      end loop;
      if F > L then
         return "";
      end if;
      return S (F .. L);
   end Trim;

   function Tokenize (Source : String) return Token_Lists.Vector is
      Result : Token_Lists.Vector;
      I      : Natural := Source'First;
      Lit    : Unbounded_String;
      Open   : Unbounded_String := To_Unbounded_String ("{{");
      Close  : Unbounded_String := To_Unbounded_String ("}}");

      function Starts (P : Natural; S : String) return Boolean is
        (P + S'Length - 1 <= Source'Last
         and then Source (P .. P + S'Length - 1) = S);

      procedure Flush is
      begin
         if Lit /= Null_Unbounded_String then
            Result.Append (Token'(Text, Lit, Null_Unbounded_String));
            Lit := Null_Unbounded_String;
         end if;
      end Flush;

      function Strip_Indent return String is
         S : constant String := To_String (Lit);
         P : Natural := S'Last;
      begin
         while P >= S'First and then Is_Blank (S (P)) loop
            P := P - 1;
         end loop;
         if P >= S'First then
            Lit := To_Unbounded_String (S (S'First .. P));
         else
            Lit := Null_Unbounded_String;
         end if;
         return S (P + 1 .. S'Last);
      end Strip_Indent;

      procedure Skip_Line_End (From : Natural) is
         Q : Natural := From;
      begin
         while Q <= Source'Last and then Is_Blank (Source (Q)) loop
            Q := Q + 1;
         end loop;
         if Q <= Source'Last and then Source (Q) = ASCII.CR then
            if Q < Source'Last and then Source (Q + 1) = ASCII.LF then
               Q := Q + 1;
            end if;
            Q := Q + 1;
         elsif Q <= Source'Last and then Source (Q) = ASCII.LF then
            Q := Q + 1;
         end if;
         I := Q;
      end Skip_Line_End;

      function Is_Standalone (Tag_Start, Tag_End : Natural) return Boolean is
         P : Natural := Tag_Start - 1;
         Q : Natural := Tag_End + 1;
      begin
         while P >= Source'First and then Is_Blank (Source (P)) loop
            P := P - 1;
         end loop;
         if P >= Source'First and then not Is_Break (Source (P)) then
            return False;
         end if;
         while Q <= Source'Last and then Is_Blank (Source (Q)) loop
            Q := Q + 1;
         end loop;
         return Q > Source'Last or else Is_Break (Source (Q));
      end Is_Standalone;

      function Handle_Standalone
        (Tag_Start, Tag_End : Natural) return Unbounded_String
      is
      begin
         if Is_Standalone (Tag_Start, Tag_End) then
            declare
               D : constant String := Strip_Indent;
            begin
               Skip_Line_End (Tag_End + 1);
               return To_Unbounded_String (D);
            end;
         else
            I := Tag_End + 1;
            return Null_Unbounded_String;
         end if;
      end Handle_Standalone;
   begin
      while I <= Source'Last loop
         if To_String (Open) = "{{" and then Starts (I, "{{{") then
            declare
               J : constant Natural :=
                 Ada.Strings.Fixed.Index (Source, "}}}", I + 3);
            begin
               if J = 0 then
                  raise Template_Error with "an unterminated tag";
               end if;
               declare
                  Tag : constant String := Trim (Source (I + 3 .. J - 1));
               begin
                  Flush;
                  Result.Append (Token'(Raw_Interp,
                    To_Unbounded_String (Tag), Null_Unbounded_String));
                  I := J + 3;
               end;
            end;
         elsif Starts (I, To_String (Open)) then
            declare
               J : constant Natural :=
                 Ada.Strings.Fixed.Index
                   (Source, To_String (Close), I + Length (Open));
            begin
               if J = 0 then
                  raise Template_Error with "an unterminated tag";
               end if;
               declare
                  Tag     : constant String :=
                    Trim (Source (I + Length (Open) .. J - 1));
                  Tag_End : constant Natural := J + Length (Close) - 1;
                  Ignore  : Unbounded_String;
               begin
                  if Tag'Length > 0 and then Tag (Tag'First) = '!' then
                     Ignore := Handle_Standalone (I, Tag_End);
                  elsif Tag'Length >= 2 and then Tag (Tag'First) = '='
                    and then Tag (Tag'Last) = '='
                  then
                     declare
                        Mid : constant String :=
                          Trim (Tag (Tag'First + 1 .. Tag'Last - 1));
                        Bl  : Natural := 0;
                     begin
                        for K in Mid'Range loop
                           if Is_Blank (Mid (K)) then
                              Bl := K;
                              exit;
                           end if;
                        end loop;
                        if Bl = 0 then
                           raise Template_Error with "a bad delimiter change";
                        end if;
                        Open  := To_Unbounded_String
                          (Mid (Mid'First .. Bl - 1));
                        Close := To_Unbounded_String
                          (Trim (Mid (Bl .. Mid'Last)));
                        Ignore := Handle_Standalone (I, Tag_End);
                     end;
                  else
                     declare
                        Kind : Token_Kind;
                        Nm : Unbounded_String;
                        Cap  : Boolean;
                     begin
                        if Tag'Length = 0 then
                           Kind := Interp;
                           Nm := Null_Unbounded_String;
                           Cap  := False;
                        elsif Tag (Tag'First) = '#' then
                           Kind := Section_Open;
                           Nm := To_Unbounded_String
                             (Trim (Tag (Tag'First + 1 .. Tag'Last)));
                           Cap := True;
                        elsif Tag (Tag'First) = '^' then
                           Kind := Inverted_Open;
                           Nm := To_Unbounded_String
                             (Trim (Tag (Tag'First + 1 .. Tag'Last)));
                           Cap := True;
                        elsif Tag (Tag'First) = '/' then
                           Kind := Section_Close;
                           Nm := To_Unbounded_String
                             (Trim (Tag (Tag'First + 1 .. Tag'Last)));
                           Cap := True;
                        elsif Tag (Tag'First) = '>' then
                           Kind := Partial;
                           Nm := To_Unbounded_String
                             (Trim (Tag (Tag'First + 1 .. Tag'Last)));
                           Cap := True;
                        elsif Tag (Tag'First) = '&' then
                           Kind := Raw_Interp;
                           Nm := To_Unbounded_String
                             (Trim (Tag (Tag'First + 1 .. Tag'Last)));
                           Cap := False;
                        elsif Tag'Length >= 2
                          and then Tag (Tag'First) = '{'
                          and then Tag (Tag'Last) = '}'
                        then
                           Kind := Raw_Interp;
                           Nm := To_Unbounded_String
                             (Trim (Tag (Tag'First + 1 .. Tag'Last - 1)));
                           Cap := False;
                        else
                           Kind := Interp;
                           Nm := To_Unbounded_String (Tag);
                           Cap := False;
                        end if;

                        if Cap then
                           declare
                              D : constant Unbounded_String :=
                                Handle_Standalone (I, Tag_End);
                           begin
                              Flush;
                              Result.Append (Token'(Kind, Nm, D));
                           end;
                        else
                           Flush;
                           Result.Append
                             (Token'(Kind, Nm, Null_Unbounded_String));
                           I := Tag_End + 1;
                        end if;
                     end;
                  end if;
               end;
            end;
         else
            Append (Lit, Source (I));
            I := I + 1;
         end if;
      end loop;
      Flush;
      return Result;
   end Tokenize;

   --  =====================================================================
   --  Name resolution and truthiness.
   --  =====================================================================

   function Is_Truthy (V : Value_Access) return Boolean is
   begin
      if V = null then
         return False;
      end if;
      case V.Kind is
         when Scalar => return To_String (V.Text) /= "";
         when List   => return not V.Items.Is_Empty;
         when Map    => return True;
      end case;
   end Is_Truthy;

   function Resolve_Head (Ctx : Context; Name : String) return Value_Access is
   begin
      for I in reverse 1 .. Ctx.Scopes.Last_Index loop
         declare
            Scope : constant Value_Access := Ctx.Scopes (I);
         begin
            if Scope.Kind = Map then
               declare
                  C : constant Value_Maps.Cursor := Scope.Fields.Find (Name);
               begin
                  if C /= Value_Maps.No_Element then
                     return Value_Maps.Element (C);
                  end if;
               end;
            end if;
         end;
      end loop;
      return null;
   end Resolve_Head;

   function Resolve_Tail
     (M : Value_Access; Name : String) return Value_Access
   is
      Dot : Natural := 0;
   begin
      for I in Name'Range loop
         if Name (I) = '.' then
            Dot := I;
            exit;
         end if;
      end loop;
      if M = null or else M.Kind /= Map then
         return null;
      end if;
      declare
         Head : constant String :=
           (if Dot = 0 then Name else Name (Name'First .. Dot - 1));
         Tail : constant String :=
           (if Dot = 0 then "" else Name (Dot + 1 .. Name'Last));
         C    : constant Value_Maps.Cursor := M.Fields.Find (Head);
      begin
         if C = Value_Maps.No_Element then
            return null;
         end if;
         if Tail = "" then
            return Value_Maps.Element (C);
         end if;
         return Resolve_Tail (Value_Maps.Element (C), Tail);
      end;
   end Resolve_Tail;

   function Resolve (Ctx : Context; Name : String) return Value_Access is
      Dot : Natural := 0;
   begin
      for I in Name'Range loop
         if Name (I) = '.' then
            Dot := I;
            exit;
         end if;
      end loop;
      declare
         Head  : constant String :=
           (if Dot = 0 then Name else Name (Name'First .. Dot - 1));
         Tail  : constant String :=
           (if Dot = 0 then "" else Name (Dot + 1 .. Name'Last));
         Found : constant Value_Access := Resolve_Head (Ctx, Head);
      begin
         if Found = null then
            return null;
         elsif Tail = "" then
            return Found;
         end if;
         return Resolve_Tail (Found, Tail);
      end;
   end Resolve;

   function String_Of (V : Value_Access) return String is
   begin
      if V = null or else V.Kind /= Scalar then
         return "";
      end if;
      return To_String (V.Text);
   end String_Of;

   --  =====================================================================
   --  Rendering.
   --  =====================================================================

   function Find_Close
     (Tokens : Token_Lists.Vector; Open : Positive) return Positive
   is
      Depth : Natural := 0;
   begin
      for K in Open .. Tokens.Last_Index loop
         case Tokens (K).Kind is
            when Section_Open | Inverted_Open =>
               Depth := Depth + 1;
            when Section_Close =>
               Depth := Depth - 1;
               if Depth = 0 then
                  return K;
               end if;
            when others =>
               null;
         end case;
      end loop;
      raise Template_Error with "a section has no closing tag";
   end Find_Close;

   function Render (Source : String; View : Context) return String is
      Tokens : constant Token_Lists.Vector := Tokenize (Source);

      function Render_Range
        (First : Positive; Last : Natural; Ctx : Context) return String
      is
         Result : Unbounded_String;
         I      : Natural := First;
      begin
         while I <= Last loop
            declare
               T : constant Token := Tokens (I);
            begin
               case T.Kind is
                  when Text =>
                     Append (Result, To_String (T.Name));
                  when Interp =>
                     declare
                        Name : constant String := To_String (T.Name);
                        V    : Value_Access;
                     begin
                        if Name = "." then
                           V := Ctx.Scopes (Ctx.Scopes.Last_Index);
                        else
                           V := Resolve (Ctx, Name);
                        end if;
                        Append (Result, Escape (String_Of (V)));
                     end;
                  when Raw_Interp =>
                     declare
                        Name : constant String := To_String (T.Name);
                        V    : Value_Access;
                     begin
                        if Name = "." then
                           V := Ctx.Scopes (Ctx.Scopes.Last_Index);
                        else
                           V := Resolve (Ctx, Name);
                        end if;
                        Append (Result, String_Of (V));
                     end;
                  when Partial =>
                     declare
                        Name : constant String := To_String (T.Name);
                     begin
                        if Store.Contains (Name) then
                           declare
                              P : constant String := Get (Name);
                              D : constant String := To_String (T.Indent);
                           begin
                              if D = "" then
                                 Append (Result, Render (P, Ctx));
                              else
                                 --  Indent the partial *source* before
                                 --  rendering, so newlines introduced by raw
                                 --  interpolation are not themselves indented.
                                 declare
                                    S : Unbounded_String;
                                 begin
                                    Append (S, D);
                                    for K in P'Range loop
                                       Append (S, P (K));
                                       if P (K) = ASCII.LF
                                         and then K < P'Last
                                       then
                                          Append (S, D);
                                       end if;
                                    end loop;
                                    Append
                                      (Result,
                                       Render (To_String (S), Ctx));
                                 end;
                              end if;
                           end;
                        end if;
                     end;
                  when Section_Open =>
                     declare
                        J    : constant Positive := Find_Close (Tokens, I);
                        Name : constant String := To_String (T.Name);
                        V    : constant Value_Access :=
                          (if Name = "." then
                              Ctx.Scopes (Ctx.Scopes.Last_Index)
                           else Resolve (Ctx, Name));
                        C    : Context := Ctx;
                     begin
                        if V = null then
                           null;
                        elsif V.Kind = List then
                           for E of V.Items loop
                              Push (C, E);
                              Append (Result,
                                Render_Range (I + 1, J - 1, C));
                              Pop (C);
                           end loop;
                        elsif Is_Truthy (V) then
                           Push (C, V);
                           Append (Result, Render_Range (I + 1, J - 1, C));
                           Pop (C);
                        end if;
                        I := J;
                     end;
                  when Inverted_Open =>
                     declare
                        J    : constant Positive := Find_Close (Tokens, I);
                        Name : constant String := To_String (T.Name);
                        V    : constant Value_Access :=
                          (if Name = "." then
                              Ctx.Scopes (Ctx.Scopes.Last_Index)
                           else Resolve (Ctx, Name));
                     begin
                        if not Is_Truthy (V) then
                           Append (Result,
                             Render_Range (I + 1, J - 1, Ctx));
                        end if;
                        I := J;
                     end;
                  when Section_Close =>
                     raise Template_Error with "unmatched closing tag";
               end case;
            end;
            I := I + 1;
         end loop;
         return To_String (Result);
      end Render_Range;
   begin
      if Tokens.Is_Empty then
         return "";
      end if;
      return Render_Range (1, Tokens.Last_Index, View);
   end Render;

   function Render_File (Name : String; View : Context) return String is
     (Render (Get (Name), View));

end Mustache;
