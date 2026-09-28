pragma Ada_2022;

with Interfaces;

--  Key derivation (crypto_kdf_*, BLAKE2b): turn one master key into many
--  independent subkeys, keyed by an 8-byte context and a 64-bit subkey id.
package Crypto.Kdf is

   Key_Size     : constant := 32;   --  crypto_kdf_KEYBYTES
   Context_Size : constant := 8;    --  crypto_kdf_CONTEXTBYTES
   Bytes_Min    : constant := 16;   --  crypto_kdf_BYTES_MIN
   Bytes_Max    : constant := 64;   --  crypto_kdf_BYTES_MAX

   --  Fresh random master key.
   function Keygen return Crypto.Byte_Array;

   --  Derive Subkey_Length bytes (Bytes_Min .. Bytes_Max) of key material from
   --  the master Key, the 8-byte Context and the Subkey_Id.  Deterministic:
   --  the same (Key, Context, Subkey_Id) yields the same subkey.  Raises
   --  Crypto_Error on a bad length, context or key size.
   function Derive_From_Key
     (Subkey_Length : Natural;
      Subkey_Id     : Interfaces.Unsigned_64;
      Context       : Crypto.Byte_Array;
      Key           : Crypto.Byte_Array) return Crypto.Byte_Array;

   --  HKDF (RFC 5869) over SHA-256/SHA-512 (crypto_kdf_hkdf_sha256/512_*).
   --  Extract turns input keying material (and an optional salt) into a
   --  fixed-length pseudorandom key; Expand derives output keying material of
   --  any length from that PRK and an info/context string.
   Hkdf_Sha256_Key_Size : constant := 32;
   Hkdf_Sha512_Key_Size : constant := 64;

   function Hkdf_Sha256_Extract (Salt, Ikm : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Hkdf_Sha256_Expand
     (Prk, Info : Crypto.Byte_Array; Length : Natural) return Crypto.Byte_Array;
   function Hkdf_Sha256_Keygen return Crypto.Byte_Array;

   function Hkdf_Sha512_Extract (Salt, Ikm : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Hkdf_Sha512_Expand
     (Prk, Info : Crypto.Byte_Array; Length : Natural) return Crypto.Byte_Array;
   function Hkdf_Sha512_Keygen return Crypto.Byte_Array;

end Crypto.Kdf;
