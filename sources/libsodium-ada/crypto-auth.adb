pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Auth is

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

   function C_Auth
     (Dg : System.Address; Inp : System.Address; Inp_Len : ULL;
      K : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_auth";

   function C_Verify
     (H : System.Address; Inp : System.Address; Inp_Len : ULL;
      K : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_auth_verify";

   procedure C_Keygen (K : System.Address)
     with Import, Convention => C, External_Name => "crypto_auth_keygen";

   function C_Hmac_Sha256_Init
     (State, Key : System.Address; Key_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha256_init";

   function C_Hmac_Sha256_Update
     (State, Inp : System.Address; Inp_Len : ULL) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha256_update";

   function C_Hmac_Sha256_Final
     (State, Dg : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha256_final";

   function C_Hmac_Sha512_Init
     (State, Key : System.Address; Key_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha512_init";

   function C_Hmac_Sha512_Update
     (State, Inp : System.Address; Inp_Len : ULL) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha512_update";

   function C_Hmac_Sha512_Final
     (State, Dg : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha512_final";

   function C_Hmac_Sha512256_Init
     (State, Key : System.Address; Key_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha512256_init";

   function C_Hmac_Sha512256_Update
     (State, Inp : System.Address; Inp_Len : ULL) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha512256_update";

   function C_Hmac_Sha512256_Final
     (State, Dg : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_auth_hmacsha512256_final";

   function Keygen return Crypto.Byte_Array is
      K : Crypto.Byte_Array (1 .. Key_Size);
   begin
      C_Keygen (K (1)'Address);
      return K;
   end Keygen;

   function Authenticate (Data, Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. Bytes);
   begin
      if Key'Length /= Key_Size then
         Fail ("key size");
      end if;
      if C_Auth (D (1)'Address, Addr (Data), ULL (Data'Length),
                 Addr (Key)) /= 0
      then
         Fail ("auth failed");
      end if;
      return D;
   end Authenticate;

   function Verify (Mac, Data, Key : Crypto.Byte_Array) return Boolean is
   begin
      if Mac'Length /= Bytes or else Key'Length /= Key_Size then
         return False;
      end if;
      return C_Verify (Addr (Mac), Addr (Data), ULL (Data'Length),
                       Addr (Key)) = 0;
   end Verify;

   function Hmac_Sha256_Init (Key : Crypto.Byte_Array) return Hmac_Sha256_State is
      S : Hmac_Sha256_State;
   begin
      if C_Hmac_Sha256_Init
        (S.Data (1)'Address, Addr (Key), Interfaces.C.size_t (Key'Length)) /= 0
      then
         Fail ("hmac-sha256 init failed");
      end if;
      return S;
   end Hmac_Sha256_Init;

   procedure Hmac_Sha256_Update
     (State : in out Hmac_Sha256_State; Data : Crypto.Byte_Array) is
   begin
      if C_Hmac_Sha256_Update
        (State.Data (1)'Address, Addr (Data), ULL (Data'Length)) /= 0
      then
         Fail ("hmac-sha256 update failed");
      end if;
   end Hmac_Sha256_Update;

   function Hmac_Sha256_Final (State : Hmac_Sha256_State)
      return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. 32);   --  crypto_auth_hmacsha256_BYTES
   begin
      if C_Hmac_Sha256_Final (State.Data (1)'Address, D (1)'Address) /= 0 then
         Fail ("hmac-sha256 final failed");
      end if;
      return D;
   end Hmac_Sha256_Final;

   function Hmac_Sha512_Init (Key : Crypto.Byte_Array) return Hmac_Sha512_State is
      S : Hmac_Sha512_State;
   begin
      if C_Hmac_Sha512_Init
        (S.Data (1)'Address, Addr (Key), Interfaces.C.size_t (Key'Length)) /= 0
      then
         Fail ("hmac-sha512 init failed");
      end if;
      return S;
   end Hmac_Sha512_Init;

   procedure Hmac_Sha512_Update
     (State : in out Hmac_Sha512_State; Data : Crypto.Byte_Array) is
   begin
      if C_Hmac_Sha512_Update
        (State.Data (1)'Address, Addr (Data), ULL (Data'Length)) /= 0
      then
         Fail ("hmac-sha512 update failed");
      end if;
   end Hmac_Sha512_Update;

   function Hmac_Sha512_Final (State : Hmac_Sha512_State)
      return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. 64);   --  crypto_auth_hmacsha512_BYTES
   begin
      if C_Hmac_Sha512_Final (State.Data (1)'Address, D (1)'Address) /= 0 then
         Fail ("hmac-sha512 final failed");
      end if;
      return D;
   end Hmac_Sha512_Final;

   function Hmac_Sha512_256_Init (Key : Crypto.Byte_Array)
      return Hmac_Sha512_State
   is
      S : Hmac_Sha512_State;
   begin
      if C_Hmac_Sha512256_Init
        (S.Data (1)'Address, Addr (Key), Interfaces.C.size_t (Key'Length)) /= 0
      then
         Fail ("hmac-sha512256 init failed");
      end if;
      return S;
   end Hmac_Sha512_256_Init;

   procedure Hmac_Sha512_256_Update
     (State : in out Hmac_Sha512_State; Data : Crypto.Byte_Array) is
   begin
      if C_Hmac_Sha512256_Update
        (State.Data (1)'Address, Addr (Data), ULL (Data'Length)) /= 0
      then
         Fail ("hmac-sha512256 update failed");
      end if;
   end Hmac_Sha512_256_Update;

   function Hmac_Sha512_256_Final (State : Hmac_Sha512_State)
      return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. 32);   --  crypto_auth_hmacsha512256_BYTES
   begin
      if C_Hmac_Sha512256_Final (State.Data (1)'Address, D (1)'Address) /= 0 then
         Fail ("hmac-sha512256 final failed");
      end if;
      return D;
   end Hmac_Sha512_256_Final;

end Crypto.Auth;
