pragma Ada_2022;

with Ada.Strings.Unbounded;

package body Json is

   use Ada.Strings.Unbounded;

   function Parse (Source : String) return Mustache.Value_Access is
      Src : constant String := Source;
      I   : Natural := Source'First;

      procedure Skip_WS is
      begin
         while I <= Src'Last
           and then (Src (I) = ' ' or else Src (I) = ASCII.HT
                     or else Src (I) = ASCII.LF or else Src (I) = ASCII.CR)
         loop
            I := I + 1;
         end loop;
      end Skip_WS;

      procedure Expect (C : Character) is
      begin
         if I > Src'Last or else Src (I) /= C then
            raise Mustache.Template_Error with "JSON parse error";
         end if;
         I := I + 1;
      end Expect;

      function Parse_String return String is
         R : Unbounded_String;
      begin
         Expect ('"');
         while I <= Src'Last and then Src (I) /= '"' loop
            if Src (I) = '\' then
               I := I + 1;
               if I > Src'Last then
                  raise Mustache.Template_Error with "JSON: bad escape";
               end if;
               case Src (I) is
                  when '"'  => Append (R, '"');
                  when '\'  => Append (R, '\');
                  when '/'  => Append (R, '/');
                  when 'b'  => Append (R, Character'Val (8));
                  when 'f'  => Append (R, Character'Val (12));
                  when 'n'  => Append (R, ASCII.LF);
                  when 'r'  => Append (R, ASCII.CR);
                  when 't'  => Append (R, ASCII.HT);
                  when others =>
                     raise Mustache.Template_Error with "JSON: unknown escape";
               end case;
               I := I + 1;
            else
               Append (R, Src (I));
               I := I + 1;
            end if;
         end loop;
         Expect ('"');
         return To_String (R);
      end Parse_String;

      function Parse_Number return String is
         F : constant Natural := I;
      begin
         while I <= Src'Last
           and then (Src (I) in '0' .. '9' or else Src (I) = 'e'
                     or else Src (I) = 'E' or else Src (I) = '+'
                     or else Src (I) = '-' or else Src (I) = '.')
         loop
            I := I + 1;
         end loop;
         return Src (F .. I - 1);
      end Parse_Number;

      function Parse_Value return Mustache.Value_Access;

      function Parse_Object return Mustache.Value_Access is
         R : constant Mustache.Value_Access := Mustache.New_Map;
      begin
         Expect ('{');
         Skip_WS;
         if I <= Src'Last and then Src (I) = '}' then
            I := I + 1;
            return R;
         end if;
         loop
            Skip_WS;
            declare
               Key : constant String := Parse_String;
            begin
               Skip_WS;
               Expect (':');
               Mustache.Insert (R, Key, Parse_Value);
            end;
            Skip_WS;
            if I <= Src'Last and then Src (I) = ',' then
               I := I + 1;
            else
               Expect ('}');
               return R;
            end if;
         end loop;
      end Parse_Object;

      function Parse_Array return Mustache.Value_Access is
         R : constant Mustache.Value_Access := Mustache.New_List;
      begin
         Expect ('[');
         Skip_WS;
         if I <= Src'Last and then Src (I) = ']' then
            I := I + 1;
            return R;
         end if;
         loop
            Mustache.Append (R, Parse_Value);
            Skip_WS;
            if I <= Src'Last and then Src (I) = ',' then
               I := I + 1;
            else
               Expect (']');
               return R;
            end if;
         end loop;
      end Parse_Array;

      function Parse_Value return Mustache.Value_Access is
      begin
         Skip_WS;
         if I > Src'Last then
            raise Mustache.Template_Error with "JSON: unexpected end";
         end if;
         case Src (I) is
            when '{' =>
               return Parse_Object;
            when '[' =>
               return Parse_Array;
            when '"' =>
               return Mustache.New_Scalar (Parse_String);
            when 't' =>
               if I + 3 <= Src'Last and then Src (I .. I + 3) = "true" then
                  I := I + 4;
                  return Mustache.New_Scalar ("true");
               end if;
               raise Mustache.Template_Error with "JSON: bad literal";
            when 'f' =>
               if I + 4 <= Src'Last and then Src (I .. I + 4) = "false" then
                  I := I + 5;
                  return Mustache.New_Scalar ("");
               end if;
               raise Mustache.Template_Error with "JSON: bad literal";
            when 'n' =>
               if I + 3 <= Src'Last and then Src (I .. I + 3) = "null" then
                  I := I + 4;
                  return Mustache.New_Scalar ("");
               end if;
               raise Mustache.Template_Error with "JSON: bad literal";
            when others =>
               return Mustache.New_Scalar (Parse_Number);
         end case;
      end Parse_Value;
   begin
      declare
         V : constant Mustache.Value_Access := Parse_Value;
      begin
         Skip_WS;
         return V;
      end;
   end Parse;

end Json;
