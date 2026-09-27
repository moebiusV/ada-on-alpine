pragma Ada_2022;


--  One-time authentication (crypto_onetimeauth_*, Poly1305): a 16-byte MAC
--  for a message under a key used only once.
package Crypto.Onetimeauth is

   Bytes    : constant := 16;
   Key_Size : constant := 32;

   function Keygen return Crypto.Byte_Array;
   function Authenticate (Data, Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Verify (Mac, Data, Key : Crypto.Byte_Array) return Boolean;

end Crypto.Onetimeauth;
