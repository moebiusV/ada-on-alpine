pragma Ada_2022;

--  A minimal JSON parser for the Mustache conformance suite: parses a JSON
--  document into a Mustache.Value tree.  Objects become maps, arrays become
--  lists, strings become scalars, numbers become scalars holding their source
--  text, true becomes the scalar "true", and false/null become empty scalars
--  (empty, so falsey as Mustache requires).  No \u escapes are handled: the
--  spec fixtures contain none.
with Mustache;

package Json is
   function Parse (Source : String) return Mustache.Value_Access;
end Json;
