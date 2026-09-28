pragma Ada_2022;

with Crypto.Raw;


--  Streaming SHA-256 / SHA-512 (crypto_hash_sha*_init/update/final): hash a
--  message in chunks without materialising the whole input.  The one-shot
--  Crypto.Hash_Sha256/Hash_Sha512 remain for whole-buffer input.
package Crypto.Hash is

   Sha256_State_Size : constant := Crypto.Raw.Hash_Sha256_Statebytes;
   Sha512_State_Size : constant := Crypto.Raw.Hash_Sha512_Statebytes;

   subtype Sha256_State is Crypto.State_Buffer (Sha256_State_Size);
   subtype Sha512_State is Crypto.State_Buffer (Sha512_State_Size);

   function Sha256_Init return Sha256_State;
   procedure Sha256_Update (State : in out Sha256_State; Chunk : Crypto.Byte_Array);
   function Sha256_Final (State : Sha256_State) return Crypto.Byte_Array;

   function Sha512_Init return Sha512_State;
   procedure Sha512_Update (State : in out Sha512_State; Chunk : Crypto.Byte_Array);
   function Sha512_Final (State : Sha512_State) return Crypto.Byte_Array;

   --  Streaming SHA-3-256 / SHA-3-512 (crypto_hash_sha3256/512_init/update/
   --  final); the state is 256 bytes for both.
   Sha3_256_State_Size : constant := 256;
   Sha3_512_State_Size : constant := 256;

   subtype Sha3_256_State is Crypto.State_Buffer (Sha3_256_State_Size);
   subtype Sha3_512_State is Crypto.State_Buffer (Sha3_512_State_Size);

   function Sha3_256_Init return Sha3_256_State;
   procedure Sha3_256_Update (State : in out Sha3_256_State; Chunk : Crypto.Byte_Array);
   function Sha3_256_Final (State : Sha3_256_State) return Crypto.Byte_Array;

   function Sha3_512_Init return Sha3_512_State;
   procedure Sha3_512_Update (State : in out Sha3_512_State; Chunk : Crypto.Byte_Array);
   function Sha3_512_Final (State : Sha3_512_State) return Crypto.Byte_Array;

end Crypto.Hash;
