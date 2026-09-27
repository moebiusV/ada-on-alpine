pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Kx is

   use type Interfaces.C.int;

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

   function C_Keypair (Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_kx_keypair";

   function C_Seed_Keypair
     (Pk, Sk, Seed : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_kx_seed_keypair";

   function C_Client_Session_Keys
     (Rx, Tx, Client_Pk, Client_Sk, Server_Pk : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kx_client_session_keys";

   function C_Server_Session_Keys
     (Rx, Tx, Server_Pk, Server_Sk, Client_Pk : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kx_server_session_keys";

   function Keygen return Keypair is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size);
      Sk : Crypto.Byte_Array (1 .. Secret_Key_Size);
   begin
      if C_Keypair (Pk (1)'Address, Sk (1)'Address) /= 0 then
         Fail ("kx keygen failed");
      end if;
      return (Public => Pk, Secret => Sk);
   end Keygen;

   function Seed_Keypair (Seed : Crypto.Byte_Array) return Keypair is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size);
      Sk : Crypto.Byte_Array (1 .. Secret_Key_Size);
   begin
      if Seed'Length /= Seed_Size then
         Fail ("seed size");
      end if;
      if C_Seed_Keypair (Pk (1)'Address, Sk (1)'Address, Addr (Seed)) /= 0 then
         Fail ("kx seed keypair failed");
      end if;
      return (Public => Pk, Secret => Sk);
   end Seed_Keypair;

   function Client_Session_Keys
     (Client_Public, Client_Secret, Server_Public : Crypto.Byte_Array)
      return Session_Keys
   is
      K : Session_Keys;
   begin
      if Client_Public'Length /= Public_Key_Size
        or else Client_Secret'Length /= Secret_Key_Size
        or else Server_Public'Length /= Public_Key_Size
      then
         Fail ("key size");
      end if;
      if C_Client_Session_Keys
        (K.Rx (1)'Address, K.Tx (1)'Address, Addr (Client_Public),
         Addr (Client_Secret), Addr (Server_Public)) /= 0
      then
         Fail ("kx client session keys failed");
      end if;
      return K;
   end Client_Session_Keys;

   function Server_Session_Keys
     (Server_Public, Server_Secret, Client_Public : Crypto.Byte_Array)
      return Session_Keys
   is
      K : Session_Keys;
   begin
      if Server_Public'Length /= Public_Key_Size
        or else Server_Secret'Length /= Secret_Key_Size
        or else Client_Public'Length /= Public_Key_Size
      then
         Fail ("key size");
      end if;
      if C_Server_Session_Keys
        (K.Rx (1)'Address, K.Tx (1)'Address, Addr (Server_Public),
         Addr (Server_Secret), Addr (Client_Public)) /= 0
      then
         Fail ("kx server session keys failed");
      end if;
      return K;
   end Server_Session_Keys;

end Crypto.Kx;
