pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Scalarmult is

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

   function C_Curve25519_Base (Q, N : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_scalarmult_curve25519_base";

   function C_Curve25519 (Q, N, P : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_scalarmult_curve25519";

   function C_Ristretto255_Base (Q, N : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_scalarmult_ristretto255_base";

   function C_Ristretto255 (Q, N, P : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_scalarmult_ristretto255";

   function C_Ed25519_Base (Q, N : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_scalarmult_ed25519_base";

   function C_Ed25519 (Q, N, P : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_scalarmult_ed25519";

   function C_Ed25519_Noclamp (Q, N, P : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_scalarmult_ed25519_noclamp";

   function Mult_Base (N : Crypto.Byte_Array) return Crypto.Byte_Array is
      Q : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if N'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      if C_Curve25519_Base (Q (1)'Address, Addr (N)) /= 0 then
         Fail ("scalarmult base failed");
      end if;
      return Q;
   end Mult_Base;

   function Mult (N, P : Crypto.Byte_Array) return Crypto.Byte_Array is
      Q : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if N'Length /= Scalar_Size or else P'Length /= Element_Size then
         Fail ("scalar or element size");
      end if;
      if C_Curve25519 (Q (1)'Address, Addr (N), Addr (P)) /= 0 then
         Fail ("scalarmult failed");
      end if;
      return Q;
   end Mult;

   function Ristretto_Mult_Base (N : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Q : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if N'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      if C_Ristretto255_Base (Q (1)'Address, Addr (N)) /= 0 then
         Fail ("ristretto base failed");
      end if;
      return Q;
   end Ristretto_Mult_Base;

   function Ristretto_Mult (N, P : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Q : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if N'Length /= Scalar_Size or else P'Length /= Element_Size then
         Fail ("scalar or element size");
      end if;
      if C_Ristretto255 (Q (1)'Address, Addr (N), Addr (P)) /= 0 then
         Fail ("ristretto failed");
      end if;
      return Q;
   end Ristretto_Mult;

   function Ed25519_Mult_Base (N : Crypto.Byte_Array) return Crypto.Byte_Array is
      Q : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if N'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      if C_Ed25519_Base (Q (1)'Address, Addr (N)) /= 0 then
         Fail ("ed25519 base failed");
      end if;
      return Q;
   end Ed25519_Mult_Base;

   function Ed25519_Mult (N, P : Crypto.Byte_Array) return Crypto.Byte_Array is
      Q : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if N'Length /= Scalar_Size or else P'Length /= Element_Size then
         Fail ("scalar or element size");
      end if;
      if C_Ed25519 (Q (1)'Address, Addr (N), Addr (P)) /= 0 then
         Fail ("ed25519 failed");
      end if;
      return Q;
   end Ed25519_Mult;

   function Ed25519_Mult_Noclamp (N, P : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Q : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if N'Length /= Scalar_Size or else P'Length /= Element_Size then
         Fail ("scalar or element size");
      end if;
      if C_Ed25519_Noclamp (Q (1)'Address, Addr (N), Addr (P)) /= 0 then
         Fail ("ed25519 noclamp failed");
      end if;
      return Q;
   end Ed25519_Mult_Noclamp;

end Crypto.Scalarmult;
