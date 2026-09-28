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

   --  Ed25519 (crypto_scalarmult_ed25519_*): the same 32-byte scalar/element
   --  shape over the Ed25519 group.  Mult_Base is q = n * B; Mult is q = n * p
   --  (clamped); Mult_Noclamp skips the scalar clamping.
   function Ed25519_Mult_Base (N : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Mult (N, P : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Mult_Noclamp (N, P : Crypto.Byte_Array)
      return Crypto.Byte_Array;

end Crypto.Scalarmult;
