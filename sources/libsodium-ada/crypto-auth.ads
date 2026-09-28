pragma Ada_2022;

with Crypto.Raw;


--  Keyed authentication.  The one-shot Authenticate/Verify are HMAC-SHA512-256
--  (crypto_auth_*, a 32-byte MAC); the streaming forms below cover the direct
--  crypto_auth_hmacsha256/512/512256 families for messages too large to hold
--  in one buffer.  Keys are any length (libsodium hashes them to the fixed
--  block size).
package Crypto.Auth is

   Bytes    : constant := 32;
   Key_Size : constant := 32;

   function Keygen return Crypto.Byte_Array;
   function Authenticate (Data, Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Verify (Mac, Data, Key : Crypto.Byte_Array) return Boolean;

   --  Streaming HMAC-SHA-256 (32-byte MAC).
   Hmac_Sha256_State_Size : constant := Crypto.Raw.Auth_Hmac_Sha256_Statebytes;
   subtype Hmac_Sha256_State is Crypto.State_Buffer (Hmac_Sha256_State_Size);
   function Hmac_Sha256_Init (Key : Crypto.Byte_Array) return Hmac_Sha256_State;
   procedure Hmac_Sha256_Update
     (State : in out Hmac_Sha256_State; Data : Crypto.Byte_Array);
   function Hmac_Sha256_Final (State : Hmac_Sha256_State)
      return Crypto.Byte_Array;

   --  Streaming HMAC-SHA-512 (64-byte MAC).
   Hmac_Sha512_State_Size : constant := Crypto.Raw.Auth_Hmac_Sha512_Statebytes;
   subtype Hmac_Sha512_State is Crypto.State_Buffer (Hmac_Sha512_State_Size);
   function Hmac_Sha512_Init (Key : Crypto.Byte_Array) return Hmac_Sha512_State;
   procedure Hmac_Sha512_Update
     (State : in out Hmac_Sha512_State; Data : Crypto.Byte_Array);
   function Hmac_Sha512_Final (State : Hmac_Sha512_State)
      return Crypto.Byte_Array;

   --  Streaming HMAC-SHA512-256 (the 32-byte truncated SHA-512 MAC; same
   --  state as Hmac_Sha512_State).
   function Hmac_Sha512_256_Init (Key : Crypto.Byte_Array)
      return Hmac_Sha512_State;
   procedure Hmac_Sha512_256_Update
     (State : in out Hmac_Sha512_State; Data : Crypto.Byte_Array);
   function Hmac_Sha512_256_Final (State : Hmac_Sha512_State)
      return Crypto.Byte_Array;

end Crypto.Auth;
