pragma Ada_2022;

--  Mustache in Ada: a complete implementation of the core Mustache spec
--  (interpolation with HTML escaping, sections, inverted sections, comments,
--  partials, delimiters, dotted names, and the implicit iterator), rendered
--  against a context -- a stack of scopes, each a tree of scalar / list /
--  map values.  Pure Ada on the GNAT runtime; no C dependencies.

with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded;

package Mustache is

   Template_Error : exception;
   --  A template that cannot be parsed: an unterminated tag, a section with
   --  no closing tag, a bad delimiter change, or a template name that was
   --  never loaded.  A missing variable or partial is NOT an error -- it
   --  renders empty, as Mustache does.

   --  =====================================================================
   --  Values.
   --  =====================================================================

   type Value;
   type Value_Access is access Value;

   package Value_Lists is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Value_Access);

   package Value_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Value_Access,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   type Value_Kind is (Scalar, List, Map);

   type Value (Kind : Value_Kind) is record
      case Kind is
         when Scalar =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when List =>
            Items : Value_Lists.Vector;
         when Map =>
            Fields : Value_Maps.Map;
      end case;
   end record;

   function New_Scalar (Text : String) return Value_Access;
   function New_List return Value_Access;
   function New_Map return Value_Access;

   procedure Append (V : Value_Access; Item : Value_Access);
   --  Add Item to the end of a list value; V must have Kind = List.

   procedure Insert (V : Value_Access; Key : String; Item : Value_Access);
   --  Bind Key to Item in a map value; V must have Kind = Map.  Binding a key
   --  already present replaces it.

   --  =====================================================================
   --  The context (the "view").
   --  =====================================================================

   type Context is record
      Scopes : Value_Lists.Vector;
   end record;
   --  A stack of scopes, top-of-stack last.  A name lookup walks from the
   --  top down, so a scope pushed by a section or partial both shadows and
   --  inherits its enclosing scopes.

   function View return Context;
   --  A context with one empty map scope -- the starting point for a view.

   procedure Put (Ctx : in out Context; Key : String; Value : String);
   procedure Put (Ctx : in out Context; Key : String; Value : Value_Access);
   --  Add Key to the top scope: a string becomes a scalar, a Value_Access is
   --  a list or a map.  Put always writes the top scope.

   procedure Push (Ctx : in out Context; Scope : Value_Access);
   procedure Pop (Ctx : in out Context);

   --  =====================================================================
   --  Rendering.
   --  =====================================================================

   function Render (Source : String; View : Context) return String;
   --  Render a template given as a string.

   function Render_File (Name : String; View : Context) return String;
   --  Render a template loaded by name (see Load / Define).

   procedure Load (Dir : String);
   --  Read every Dir/*.tmpl, keyed by its base name.

   procedure Define (Name : String; Source : String);
   --  Register a template (a partial) by name, from a string.

   procedure Reset;
   --  Forget every template defined with Load or Define.

   function Get (Name : String) return String;
   --  The loaded text of the template named Name.

end Mustache;
