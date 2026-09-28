pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Hash is

   use type Interfaces.C.int;

   type ULL is mod 2 ** 64;
   pragma Convention (C, ULL);

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

   function C_Sha256_Init (State : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha256_init";

   function C_Sha256_Update
     (State : System.Address; Inp : System.Address; Inp_Len : ULL)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha256_update";

   function C_Sha256_Final
     (State : System.Address; Dg : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha256_final";

   function C_Sha512_Init (State : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha512_init";

   function C_Sha512_Update
     (State : System.Address; Inp : System.Address; Inp_Len : ULL)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha512_update";

   function C_Sha512_Final
     (State : System.Address; Dg : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha512_final";

   function Sha256_Init return Sha256_State is
      S : Sha256_State;
   begin
      if C_Sha256_Init (S.Data (1)'Address) /= 0 then
         Fail ("sha256 init failed");
      end if;
      return S;
   end Sha256_Init;

   procedure Sha256_Update (State : in out Sha256_State; Chunk : Crypto.Byte_Array) is
   begin
      if C_Sha256_Update
        (State.Data (1)'Address, Addr (Chunk), ULL (Chunk'Length)) /= 0
      then
         Fail ("sha256 update failed");
      end if;
   end Sha256_Update;

   function Sha256_Final (State : Sha256_State) return Crypto.Byte_Array is
      D : Crypto.Byte_Array (1 .. Crypto.Hash256_Size);
   begin
      if C_Sha256_Final (State.Data (1)'Address, D (1)'Address) /= 0 then
         Fail ("sha256 final failed");
      end if;
      return D;
   end Sha256_Final;

   function Sha512_Init return Sha512_State is
      S : Sha512_State;
   begin
      if C_Sha512_Init (S.Data (1)'Address) /= 0 then
         Fail ("sha512 init failed");
      end if;
      return S;
   end Sha512_Init;

   procedure Sha512_Update (State : in out Sha512_State; Chunk : Crypto.Byte_Array) is
   begin
      if C_Sha512_Update
        (State.Data (1)'Address, Addr (Chunk), ULL (Chunk'Length)) /= 0
      then
         Fail ("sha512 update failed");
      end if;
   end Sha512_Update;

   function Sha512_Final (State : Sha512_State) return Crypto.Byte_Array is
      D : Crypto.Byte_Array (1 .. Crypto.Hash512_Size);
   begin
      if C_Sha512_Final (State.Data (1)'Address, D (1)'Address) /= 0 then
         Fail ("sha512 final failed");
      end if;
      return D;
   end Sha512_Final;

end Crypto.Hash;
