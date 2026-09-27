pragma Ada_2022;


--  Scalar multiplication over Curve25519 and Ristretto255 (crypto_scalarmult_*).
--  Each scalar and element is Scalar_Size / Element_Size bytes.
package Crypto.Scalarmult is

   Scalar_Size  : constant := 32;   --  crypto_scalarmult_SCALARBYTES
   Element_Size : constant := 32;   --  crypto_scalarmult_BYTES

   --  Curve25519: q = n * B (base point) or q = n * p.
   function Mult_Base (N : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Mult (N, P : Crypto.Byte_Array) return Crypto.Byte_Array;

   --  Ristretto255: q = n * B (base point) or q = n * p.
   function Ristretto_Mult_Base (N : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Ristretto_Mult (N, P : Crypto.Byte_Array)
      return Crypto.Byte_Array;

end Crypto.Scalarmult;
