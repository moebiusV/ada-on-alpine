pragma Ada_2022;


--  Keyed authentication (crypto_auth_*, HMAC-SHA512-256): a 32-byte MAC.
package Crypto.Auth is

   Bytes    : constant := 32;
   Key_Size : constant := 32;

   function Keygen return Crypto.Byte_Array;
   function Authenticate (Data, Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Verify (Mac, Data, Key : Crypto.Byte_Array) return Boolean;

end Crypto.Auth;
