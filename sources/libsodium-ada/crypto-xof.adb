pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Xof is

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

   function C_Shake128_Init (State : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_xof_shake128_init";

   function C_Shake128_Update
     (State, Inp : System.Address; Inp_Len : ULL) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_xof_shake128_update";

   function C_Shake128_Squeeze
     (State, Buf : System.Address; Out_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_xof_shake128_squeeze";

   function C_Shake256_Init (State : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_xof_shake256_init";

   function C_Shake256_Update
     (State, Inp : System.Address; Inp_Len : ULL) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_xof_shake256_update";

   function C_Shake256_Squeeze
     (State, Buf : System.Address; Out_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_xof_shake256_squeeze";

   function Shake128_Init return Shake128_State is
      S : Shake128_State;
   begin
      if C_Shake128_Init (S.Data (1)'Address) /= 0 then
         Fail ("shake128 init failed");
      end if;
      return S;
   end Shake128_Init;

   procedure Shake128_Update
     (State : in out Shake128_State; Chunk : Crypto.Byte_Array) is
   begin
      if C_Shake128_Update
        (State.Data (1)'Address, Addr (Chunk), ULL (Chunk'Length)) /= 0
      then
         Fail ("shake128 update failed");
      end if;
   end Shake128_Update;

   function Shake128_Squeeze
     (State : in out Shake128_State; Length : Natural) return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. Length);
   begin
      if C_Shake128_Squeeze
        (State.Data (1)'Address, D (1)'Address,
         Interfaces.C.size_t (Length)) /= 0
      then
         Fail ("shake128 squeeze failed");
      end if;
      return D;
   end Shake128_Squeeze;

   function Shake128 (Data : Crypto.Byte_Array; Length : Natural)
      return Crypto.Byte_Array
   is
      S : Shake128_State := Shake128_Init;
   begin
      Shake128_Update (S, Data);
      return Shake128_Squeeze (S, Length);
   end Shake128;

   function Shake256_Init return Shake256_State is
      S : Shake256_State;
   begin
      if C_Shake256_Init (S.Data (1)'Address) /= 0 then
         Fail ("shake256 init failed");
      end if;
      return S;
   end Shake256_Init;

   procedure Shake256_Update
     (State : in out Shake256_State; Chunk : Crypto.Byte_Array) is
   begin
      if C_Shake256_Update
        (State.Data (1)'Address, Addr (Chunk), ULL (Chunk'Length)) /= 0
      then
         Fail ("shake256 update failed");
      end if;
   end Shake256_Update;

   function Shake256_Squeeze
     (State : in out Shake256_State; Length : Natural) return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. Length);
   begin
      if C_Shake256_Squeeze
        (State.Data (1)'Address, D (1)'Address,
         Interfaces.C.size_t (Length)) /= 0
      then
         Fail ("shake256 squeeze failed");
      end if;
      return D;
   end Shake256_Squeeze;

   function Shake256 (Data : Crypto.Byte_Array; Length : Natural)
      return Crypto.Byte_Array
   is
      S : Shake256_State := Shake256_Init;
   begin
      Shake256_Update (S, Data);
      return Shake256_Squeeze (S, Length);
   end Shake256;

end Crypto.Xof;
