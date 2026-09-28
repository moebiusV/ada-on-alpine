pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Kdf is

   use type Interfaces.C.int;

   type ULL is mod 2 ** 64;
   pragma Convention (C, ULL);

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

   procedure C_Keygen (K : System.Address)
     with Import, Convention => C, External_Name => "crypto_kdf_keygen";

   function C_Derive
     (Subkey : System.Address; Subkey_Len : Interfaces.C.size_t;
      Subkey_Id : ULL;
      Ctx : System.Address;
      Key : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kdf_derive_from_key";

   function Keygen return Crypto.Byte_Array is
      K : Crypto.Byte_Array (1 .. Key_Size);
   begin
      C_Keygen (K (1)'Address);
      return K;
   end Keygen;

   function Derive_From_Key
     (Subkey_Length : Natural;
      Subkey_Id     : Interfaces.Unsigned_64;
      Context       : Crypto.Byte_Array;
      Key           : Crypto.Byte_Array) return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. Subkey_Length);
   begin
      if Subkey_Length < Bytes_Min or else Subkey_Length > Bytes_Max then
         Fail ("subkey length out of range");
      end if;
      if Context'Length /= Context_Size then
         Fail ("context size");
      end if;
      if Key'Length /= Key_Size then
         Fail ("key size");
      end if;
      if C_Derive (D (1)'Address, Interfaces.C.size_t (Subkey_Length),
                   ULL (Subkey_Id), Addr (Context), Addr (Key)) /= 0
      then
         Fail ("kdf derive failed");
      end if;
      return D;
   end Derive_From_Key;

end Crypto.Kdf;
