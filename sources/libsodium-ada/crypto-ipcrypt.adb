pragma Ada_2022;

with System;

package body Crypto.Ipcrypt is

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
     with Import, Convention => C, External_Name => "crypto_ipcrypt_keygen";

   procedure C_Encrypt (Outp, Inp, K : System.Address)
     with Import, Convention => C, External_Name => "crypto_ipcrypt_encrypt";

   procedure C_Decrypt (Outp, Inp, K : System.Address)
     with Import, Convention => C, External_Name => "crypto_ipcrypt_decrypt";

   function Keygen return Crypto.Byte_Array is
      K : Crypto.Byte_Array (1 .. Key_Size);
   begin
      C_Keygen (K (1)'Address);
      return K;
   end Keygen;

   function Encrypt (Block, Key : Crypto.Byte_Array) return Crypto.Byte_Array is
      C : Crypto.Byte_Array (1 .. Bytes);
   begin
      if Block'Length /= Bytes or else Key'Length /= Key_Size then
         Fail ("block or key size");
      end if;
      C_Encrypt (C (1)'Address, Addr (Block), Addr (Key));
      return C;
   end Encrypt;

   function Decrypt (Block, Key : Crypto.Byte_Array) return Crypto.Byte_Array is
      C : Crypto.Byte_Array (1 .. Bytes);
   begin
      if Block'Length /= Bytes or else Key'Length /= Key_Size then
         Fail ("block or key size");
      end if;
      C_Decrypt (C (1)'Address, Addr (Block), Addr (Key));
      return C;
   end Decrypt;

end Crypto.Ipcrypt;
