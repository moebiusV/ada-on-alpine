pragma Ada_2022;


--  Key exchange (crypto_kx_*, X25519): each side derives a pair of session
--  keys from its own keypair and the peer's public key.  The two sides agree:
--  client Rx/Tx mirrors the server Tx/Rx.
package Crypto.Kx is

   Public_Key_Size  : constant := 32;
   Secret_Key_Size  : constant := 32;
   Seed_Size        : constant := 32;
   Session_Key_Size : constant := 32;

   type Keypair is record
      Public : Crypto.Byte_Array (1 .. Public_Key_Size);
      Secret : Crypto.Byte_Array (1 .. Secret_Key_Size);
   end record;

   type Session_Keys is record
      Rx : Crypto.Byte_Array (1 .. Session_Key_Size);
      Tx : Crypto.Byte_Array (1 .. Session_Key_Size);
   end record;

   function Keygen return Keypair;
   function Seed_Keypair (Seed : Crypto.Byte_Array) return Keypair;

   function Client_Session_Keys
     (Client_Public, Client_Secret, Server_Public : Crypto.Byte_Array)
      return Session_Keys;
   function Server_Session_Keys
     (Server_Public, Server_Secret, Client_Public : Crypto.Byte_Array)
      return Session_Keys;

end Crypto.Kx;
