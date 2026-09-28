pragma Ada_2022;


--  Extendable-output functions (crypto_xof_*, SHAKE128/SHAKE256): absorb the
--  message, then squeeze out as many digest bytes as the caller needs (128- or
--  256-bit security respectively).  Unkeyed, unlike the SHA-2 hashes.
package Crypto.Xof is

   Shake128_State_Size : constant := 256;
   Shake256_State_Size : constant := 256;

   subtype Shake128_State is Crypto.State_Buffer (Shake128_State_Size);
   subtype Shake256_State is Crypto.State_Buffer (Shake256_State_Size);

   --  One-shot: absorb Data and squeeze Length bytes of output.
   function Shake128 (Data : Crypto.Byte_Array; Length : Natural)
      return Crypto.Byte_Array;
   function Shake256 (Data : Crypto.Byte_Array; Length : Natural)
      return Crypto.Byte_Array;

   --  Streaming: init, feed chunks with Update, then Squeeze to finalise and
   --  emit Length bytes.
   function Shake128_Init return Shake128_State;
   procedure Shake128_Update
     (State : in out Shake128_State; Chunk : Crypto.Byte_Array);
   function Shake128_Squeeze
     (State : in out Shake128_State; Length : Natural) return Crypto.Byte_Array;

   function Shake256_Init return Shake256_State;
   procedure Shake256_Update
     (State : in out Shake256_State; Chunk : Crypto.Byte_Array);
   function Shake256_Squeeze
     (State : in out Shake256_State; Length : Natural) return Crypto.Byte_Array;

end Crypto.Xof;
