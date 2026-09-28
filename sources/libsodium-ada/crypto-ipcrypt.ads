pragma Ada_2022;


--  ipcrypt (crypto_ipcrypt_*): a deterministic 16-byte block cipher with a
--  16-byte key and no nonce, for anonymising small fixed-size values such as
--  IPv4 addresses or account ids.  Encrypt and Decrypt are each other's
--  inverse; there is no authentication.
package Crypto.Ipcrypt is

   Bytes    : constant := 16;
   Key_Size : constant := 16;

   function Keygen return Crypto.Byte_Array;
   function Encrypt (Block, Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Decrypt (Block, Key : Crypto.Byte_Array) return Crypto.Byte_Array;

end Crypto.Ipcrypt;
