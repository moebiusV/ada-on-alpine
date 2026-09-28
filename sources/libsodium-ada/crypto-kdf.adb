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

   function C_Hkdf_Sha256_Extract
     (Prk, Salt : System.Address; Salt_Len : Interfaces.C.size_t;
      Ikm : System.Address; Ikm_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kdf_hkdf_sha256_extract";

   function C_Hkdf_Sha256_Expand
     (Buf : System.Address; Out_Len : Interfaces.C.size_t;
      Ctx : System.Address; Ctx_Len : Interfaces.C.size_t;
      Prk : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kdf_hkdf_sha256_expand";

   procedure C_Hkdf_Sha256_Keygen (Prk : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_kdf_hkdf_sha256_keygen";

   function C_Hkdf_Sha512_Extract
     (Prk, Salt : System.Address; Salt_Len : Interfaces.C.size_t;
      Ikm : System.Address; Ikm_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kdf_hkdf_sha512_extract";

   function C_Hkdf_Sha512_Expand
     (Buf : System.Address; Out_Len : Interfaces.C.size_t;
      Ctx : System.Address; Ctx_Len : Interfaces.C.size_t;
      Prk : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kdf_hkdf_sha512_expand";

   procedure C_Hkdf_Sha512_Keygen (Prk : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_kdf_hkdf_sha512_keygen";

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

   function Hkdf_Sha256_Extract (Salt, Ikm : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Prk : Crypto.Byte_Array (1 .. Hkdf_Sha256_Key_Size);
   begin
      if C_Hkdf_Sha256_Extract
        (Prk (1)'Address, Addr (Salt), Interfaces.C.size_t (Salt'Length),
         Addr (Ikm), Interfaces.C.size_t (Ikm'Length)) /= 0
      then
         Fail ("hkdf-sha256 extract failed");
      end if;
      return Prk;
   end Hkdf_Sha256_Extract;

   function Hkdf_Sha256_Expand
     (Prk, Info : Crypto.Byte_Array; Length : Natural) return Crypto.Byte_Array
   is
      Buf : Crypto.Byte_Array (1 .. Length);
   begin
      if Prk'Length /= Hkdf_Sha256_Key_Size then
         Fail ("prk size");
      end if;
      if C_Hkdf_Sha256_Expand
        (Buf (1)'Address, Interfaces.C.size_t (Length),
         Addr (Info), Interfaces.C.size_t (Info'Length), Addr (Prk)) /= 0
      then
         Fail ("hkdf-sha256 expand failed");
      end if;
      return Buf;
   end Hkdf_Sha256_Expand;

   function Hkdf_Sha256_Keygen return Crypto.Byte_Array is
      K : Crypto.Byte_Array (1 .. Hkdf_Sha256_Key_Size);
   begin
      C_Hkdf_Sha256_Keygen (K (1)'Address);
      return K;
   end Hkdf_Sha256_Keygen;

   function Hkdf_Sha512_Extract (Salt, Ikm : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Prk : Crypto.Byte_Array (1 .. Hkdf_Sha512_Key_Size);
   begin
      if C_Hkdf_Sha512_Extract
        (Prk (1)'Address, Addr (Salt), Interfaces.C.size_t (Salt'Length),
         Addr (Ikm), Interfaces.C.size_t (Ikm'Length)) /= 0
      then
         Fail ("hkdf-sha512 extract failed");
      end if;
      return Prk;
   end Hkdf_Sha512_Extract;

   function Hkdf_Sha512_Expand
     (Prk, Info : Crypto.Byte_Array; Length : Natural) return Crypto.Byte_Array
   is
      Buf : Crypto.Byte_Array (1 .. Length);
   begin
      if Prk'Length /= Hkdf_Sha512_Key_Size then
         Fail ("prk size");
      end if;
      if C_Hkdf_Sha512_Expand
        (Buf (1)'Address, Interfaces.C.size_t (Length),
         Addr (Info), Interfaces.C.size_t (Info'Length), Addr (Prk)) /= 0
      then
         Fail ("hkdf-sha512 expand failed");
      end if;
      return Buf;
   end Hkdf_Sha512_Expand;

   function Hkdf_Sha512_Keygen return Crypto.Byte_Array is
      K : Crypto.Byte_Array (1 .. Hkdf_Sha512_Key_Size);
   begin
      C_Hkdf_Sha512_Keygen (K (1)'Address);
      return K;
   end Hkdf_Sha512_Keygen;

end Crypto.Kdf;
