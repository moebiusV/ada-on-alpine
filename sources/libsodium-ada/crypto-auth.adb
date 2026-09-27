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

end Crypto.Auth;
