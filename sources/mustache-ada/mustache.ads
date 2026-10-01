pragma Ada_2022;

--  Mustache in Ada: a small, strict subset of Mustache for code generation.
--  Render a template against a context -- a stack of scopes, each a tree of
--  scalar / list / map values -- with the tags README.md lists.  Pure Ada on
--  the GNAT runtime; no C dependencies.

with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded;

package Mustache is

   Template_Error : exception;
   --  A missing template, an unfilled or non-scalar {{var}}, a {{#each}} over
   --  a non-list, an unterminated section, or a key bound twice.

   procedure Load (Dir : String);
   --  Read every Dir/*.tmpl into the store, keyed by its base name (the file
   --  name without ".tmpl").  A missing directory or unreadable file raises
   --  Template_Error.

   function Get (Name : String) return String;
   --  The loaded text of the template named Name (base name, no ".tmpl").

   --  The context model: a value is a scalar, a list, or a map, recursively.
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

   --  Builders.  Each returns a fresh heap value; a program builds a context,
   --  renders it, and drops it, so no deallocation is needed.
   function New_Scalar (Text : String) return Value_Access;
   function New_List return Value_Access;
   function New_Map return Value_Access;

   procedure Append (V : Value_Access; Item : Value_Access);
   --  Add Item to the end of a list value; V must have Kind = List.

   procedure Insert (V : Value_Access; Key : String; Item : Value_Access);
   --  Bind Key to Item in a map value; V must have Kind = Map.  Binding a key
   --  already present is an error.

   --  A rendering context: a stack of scopes, top-of-stack last.  A name
   --  lookup walks from the top down, so a scope pushed by {{#each}} or a
   --  partial both shadows and inherits its enclosing scopes.
   type Context is record
      Scopes : Value_Lists.Vector;
   end record;

   function New_Context (Root : Value_Access) return Context;
   --  A context whose single scope is Root.

   procedure Push (Ctx : in out Context; Scope : Value_Access);
   --  Push a scope onto the top of the stack.

   procedure Pop (Ctx : in out Context);
   --  Drop the top scope.

   function Render (Name : String; Ctx : Context) return String;
   --  Render the loaded template Name against Ctx.

   function Render_Text (Source : String; Ctx : Context) return String;
   --  Render a template given as Source text (not loaded by name).

end Mustache;
