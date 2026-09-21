pragma Ada_2022;

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with ASTBNF;

--  ASTBNF_Match: the matcher.  Given a parsed schema and a token stream,
--  recognize whether the tokens spell out the schema's root rule, consuming
--  the whole stream up to the trailing Eof.
--
--  The tokens are generic: a kind plus optional text.  hbnf's Lex produces
--  the stream; a small adapter maps its token kinds onto these.  Comments
--  are not matched by the structural rules — the adapter drops them, and the
--  binder (a later layer) will place them by their position relative to the
--  Semicolon/Newline tokens.

package ASTBNF_Match is

   use Ada.Strings.Unbounded;

   type Token_Kind is (Atom, Str, Int, Dec, Comment, Punct, Newline, Eof);
   --  Atom = a bare word; Str = a quoted string; Int/Dec = numbers;
   --  Punct = a punctuation character (Text holds it); Newline = a line
   --  break; Comment = a comment (not matched); Eof = end of input.

   type Token is record
      Kind : Token_Kind := Eof;
      Text : Unbounded_String := Null_Unbounded_String;
   end record;

   package Token_Vectors is new Ada.Containers.Vectors (Positive, Token);

   --  True if Tokens (ending in Eof) match the rule named Root.
   function Match
     (Rules  : ASTBNF.Rule_Vectors.Vector;
      Tokens : Token_Vectors.Vector;
      Root   : String) return Boolean;

end ASTBNF_Match;
