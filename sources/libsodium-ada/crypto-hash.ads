pragma Ada_2022;


--  Streaming SHA-256 / SHA-512 (crypto_hash_sha*_init/update/final): hash a
--  message in chunks without materialising the whole input.  The one-shot
--  Crypto.Hash_Sha256/Hash_Sha512 remain for whole-buffer input.
package Crypto.Hash is

   Sha256_State_Size : constant := 104;   --  crypto_hash_sha256_statebytes
   Sha512_State_Size : constant := 208;   --  crypto_hash_sha512_statebytes

   subtype Sha256_State is Crypto.State_Buffer (Sha256_State_Size);
   subtype Sha512_State is Crypto.State_Buffer (Sha512_State_Size);

   function Sha256_Init return Sha256_State;
   procedure Sha256_Update (State : in out Sha256_State; Chunk : Crypto.Byte_Array);
   function Sha256_Final (State : Sha256_State) return Crypto.Byte_Array;

   function Sha512_Init return Sha512_State;
   procedure Sha512_Update (State : in out Sha512_State; Chunk : Crypto.Byte_Array);
   function Sha512_Final (State : Sha512_State) return Crypto.Byte_Array;

end Crypto.Hash;
