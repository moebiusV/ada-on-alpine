pragma Ada_2022;

package body ASTBNF_Match is

   use ASTBNF;

   type Matcher is record
      Rules  : ASTBNF.Rule_Vectors.Vector;
      Tokens : Token_Vectors.Vector;
   end record;

   function Last (M : Matcher) return Natural is
     (Natural (M.Tokens.Length));

   function Find_Rule (M : Matcher; Name : String) return Natural is
   begin
      for I in 1 .. Natural (M.Rules.Length) loop
         if To_String (M.Rules (I).Name) = Name then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Rule;

   --  Is Name a built-in core type (not a rule reference)?
   function Is_Core (Name : String) return Boolean is
   begin
      if Name = "atom" or else Name = "word" or else Name = "str"
        or else Name = "int" or else Name = "dec" or else Name = "float"
        or else Name = "bool" or else Name = "flag" or else Name = "comment"
      then
         return True;
      end if;
      if Name'Length >= 2 then
         declare
            P : constant Character := Name (Name'First);
            R : constant String := Name (Name'First + 1 .. Name'Last);
         begin
            return (P = 'u' or else P = 'i')
              and then (for all C of R => C in '0' .. '9');
         end;
      end if;
      return False;
   end Is_Core;

   --  Match a literal terminal against the token at Pos.  A one-character
   --  punctuation matches a Punct token, a newline matches a Newline token,
   --  anything else is a keyword matched against an Atom token's text.
   function Match_Literal (M : Matcher; Lit : String; Pos : Natural)
     return Natural
   is
      T : Token;
   begin
      if Pos > Last (M) then
         return 0;
      end if;
      T := M.Tokens (Pos);
      if Lit'Length = 1 and then Lit (Lit'First) = ASCII.LF then
         return (if T.Kind = Newline then Pos + 1 else 0);
      elsif Lit'Length = 1 and then
        (Lit (Lit'First) not in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_')
      then
         return (if T.Kind = Punct and then To_String (T.Text) = Lit
                 then Pos + 1 else 0);
      else
         return (if T.Kind = Atom and then To_String (T.Text) = Lit
                 then Pos + 1 else 0);
      end if;
   end Match_Literal;

   --  Match a built-in core type against the token at Pos.
   function Match_Core (M : Matcher; Name : String; Pos : Natural)
     return Natural
   is
      T : Token;
   begin
      if Pos > Last (M) then
         return 0;
      end if;
      T := M.Tokens (Pos);
      if Name = "str" then
         return (if T.Kind = Str then Pos + 1 else 0);
      elsif Name = "atom" or else Name = "word" then
         return (if T.Kind = Atom then Pos + 1 else 0);
      elsif Name = "int" then
         return (if T.Kind = Int then Pos + 1 else 0);
      elsif Name = "dec" or else Name = "float" then
         return (if T.Kind = Dec then Pos + 1 else 0);
      elsif Name = "bool" or else Name = "flag" then
         return (if T.Kind = Atom then Pos + 1 else 0);
      elsif Name = "comment" then
         return (if T.Kind = Comment then Pos + 1 else 0);
      else
         return (if T.Kind = Int then Pos + 1 else 0);  --  u8..u64 / i8..i64
      end if;
   end Match_Core;

   --  Mutually recursive match functions (PEG-style: ordered choice, greedy
   --  repetition).  Each returns the token index just past the match, or 0.
   function Match_Alts
     (M : Matcher; Els : Element_Vectors.Vector; Pos : Natural) return Natural;
   function Match_Concat
     (M : Matcher; Els : Element_Vectors.Vector; From, To : Natural;
      Pos : Natural) return Natural;
   function Match_Element
     (M : Matcher; E : Element_Access; Pos : Natural) return Natural;
   function Match_Atom
     (M : Matcher; E : Element_Access; Pos : Natural) return Natural;
   function Match_Rule
     (M : Matcher; Name : String; Pos : Natural) return Natural;

   function Match_Rule (M : Matcher; Name : String; Pos : Natural)
     return Natural
   is
      RI : constant Natural := Find_Rule (M, Name);
   begin
      if RI = 0 then
         raise ASTBNF.Parse_Error with "undefined rule: " & Name;
      end if;
      return Match_Alts (M, M.Rules (RI).Pattern, Pos);
   end Match_Rule;

   function Match_Atom (M : Matcher; E : Element_Access; Pos : Natural)
     return Natural is
   begin
      case E.Kind is
         when Literal => return Match_Literal (M, To_String (E.Lit), Pos);
         when Name =>
            if Is_Core (To_String (E.Name)) then
               return Match_Core (M, To_String (E.Name), Pos);
            else
               return Match_Rule (M, To_String (E.Name), Pos);
            end if;
         when Group => return Match_Alts (M, E.Items, Pos);
         when Alt   => return 0;
      end case;
   end Match_Atom;

   --  Match the element body between E.Min and E.Max times (greedy).
   function Match_Element (M : Matcher; E : Element_Access; Pos : Natural)
     return Natural
   is
      Count : Natural := 0;
      P     : Natural := Pos;
   begin
      loop
         exit when E.Max >= 0 and then Count >= E.Max;
         declare
            Next : constant Natural := Match_Atom (M, E, P);
         begin
            exit when Next = 0;
            P := Next;
            Count := Count + 1;
         end;
      end loop;
      return (if Count >= E.Min then P else 0);
   end Match_Element;

   --  Match a concatenation of elements Els (From .. To), in sequence.
   function Match_Concat
     (M : Matcher; Els : Element_Vectors.Vector; From, To : Natural;
      Pos : Natural) return Natural
   is
      P : Natural := Pos;
   begin
      for K in From .. To loop
         P := Match_Element (M, Els (K), P);
         if P = 0 then
            return 0;
         end if;
      end loop;
      return P;
   end Match_Concat;

   --  Match an alternation: the flat list is split on Alt, each segment a
   --  concatenation; the first that matches wins (ordered choice).
   function Match_Alts
     (M : Matcher; Els : Element_Vectors.Vector; Pos : Natural) return Natural
   is
      Alt_First : Natural := 1;
   begin
      for K in 1 .. Natural (Els.Length) + 1 loop
         if K > Natural (Els.Length) or else Els (K).Kind = Alt then
            declare
               R : constant Natural :=
                 Match_Concat (M, Els, Alt_First, K - 1, Pos);
            begin
               if R /= 0 then
                  return R;
               end if;
            end;
            Alt_First := K + 1;
         end if;
      end loop;
      return 0;
   end Match_Alts;

   function Match
     (Rules  : ASTBNF.Rule_Vectors.Vector;
      Tokens : Token_Vectors.Vector;
      Root   : String) return Boolean
   is
      M  : constant Matcher := (Rules => Rules, Tokens => Tokens);
      RI : constant Natural := Find_Rule (M, Root);
      R  : Natural;
   begin
      if RI = 0 then
         raise ASTBNF.Parse_Error with "no root rule: " & Root;
      end if;
      R := Match_Alts (M, M.Rules (RI).Pattern, 1);
      return R /= 0 and then R <= Last (M)
        and then M.Tokens (R).Kind = Eof;
   end Match;

end ASTBNF_Match;
