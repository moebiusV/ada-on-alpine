pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Shorthash is

   use type Interfaces.C.int;

   function Addr (B : Crypto.Byte_Array) return System.Address is
   begin
      if B'Length = 0 then
         return System.Null_Address;
      end if;
      return B (B'First)'Address;
   end Addr;

   procedure Fail (S : String) is
   begin
      raise Crypto.Crypto_Error with S;
   end Fail;

   function C_Hash
     (Dg : System.Address; Inp : System.Address; Inp_Len : Interfaces.C.size_t;
      K : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_shorthash";

   procedure C_Keygen (K : System.Address)
     with Import, Convention => C, External_Name => "crypto_shorthash_keygen";

   function Keygen return Crypto.Byte_Array is
      K : Crypto.Byte_Array (1 .. Key_Size);
   begin
      C_Keygen (K (1)'Address);
      return K;
   end Keygen;

   function Hash (Data, Key : Crypto.Byte_Array) return Crypto.Byte_Array is
      D : Crypto.Byte_Array (1 .. Bytes);
   begin
      if Key'Length /= Key_Size then
         Fail ("key size");
      end if;
      if C_Hash (D (1)'Address, Addr (Data),
                 Interfaces.C.size_t (Data'Length), Addr (Key)) /= 0
      then
         Fail ("shorthash failed");
      end if;
      return D;
   end Hash;

end Crypto.Shorthash;
