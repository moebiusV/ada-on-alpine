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

end Crypto.Kdf;
