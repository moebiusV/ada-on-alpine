pragma Ada_2022;


--  Short, keyed hash (crypto_shorthash_*, SipHash-2-4): an 8-byte digest over
--  a message, keyed so an attacker cannot force collisions without the key.
package Crypto.Shorthash is

   Bytes    : constant := 8;
   Key_Size : constant := 16;

   function Keygen return Crypto.Byte_Array;
   function Hash (Data, Key : Crypto.Byte_Array) return Crypto.Byte_Array;

end Crypto.Shorthash;
