pragma Ada_2022;


--  The low-level core primitives (crypto_core_*): the raw building blocks the
--  higher-level primitives are assembled from.  These are for expert use --
--  building or verifying protocols -- not general message protection.
package Crypto.Core is

   -------------------------------------------------------------
   --  Salsa family cores (crypto_core_{salsa20,salsa2012,salsa208,
   --  hsalsa20,hchacha20}): the raw permutation over a 16-byte input, 32-byte
   --  key and 16-byte constant.
   -------------------------------------------------------------
   Salsa_Output_Size   : constant := 64;
   Salsa_Input_Size    : constant := 16;
   Salsa_Key_Size      : constant := 32;
   Salsa_Constant_Size : constant := 16;
   Short_Output_Size   : constant := 32;   --  hsalsa20 / hchacha20

   function Salsa20 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Salsa2012 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Salsa208 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function HSalsa20 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function HChaCha20 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array;

   -------------------------------------------------------------
   --  Ed25519 core (crypto_core_ed25519_*): point and scalar arithmetic over
   --  32-byte elements and 32-byte scalars.
   -------------------------------------------------------------
   Element_Size             : constant := 32;
   Uniform_Size             : constant := 32;
   Hash_Size                : constant := 64;
   Scalar_Size              : constant := 32;
   Nonreduced_Scalar_Size   : constant := 64;

   function Ed25519_Is_Valid_Point (P : Crypto.Byte_Array) return Boolean;
   function Ed25519_Add (P, Q : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Sub (P, Q : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_From_Uniform (R : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_From_Hash (H : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Random return Crypto.Byte_Array;
   function Ed25519_Scalar_Random return Crypto.Byte_Array;
   function Ed25519_Scalar_Invert (S : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Scalar_Negate (S : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Scalar_Complement (S : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Ed25519_Scalar_Add (X, Y : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Scalar_Sub (X, Y : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Scalar_Mul (X, Y : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ed25519_Scalar_Reduce (S : Crypto.Byte_Array) return Crypto.Byte_Array;

   -------------------------------------------------------------
   --  Ristretto255 core (crypto_core_ristretto255_*): the same point/scalar
   --  arithmetic over the prime-order Ristretto255 group.
   -------------------------------------------------------------
   Ristretto_Element_Size           : constant := 32;
   Ristretto_Hash_Size              : constant := 64;
   Ristretto_Scalar_Size            : constant := 32;
   Ristretto_Nonreduced_Scalar_Size : constant := 64;

   function Ristretto_Is_Valid_Point (P : Crypto.Byte_Array) return Boolean;
   function Ristretto_Add (P, Q : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ristretto_Sub (P, Q : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ristretto_From_Hash (H : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Ristretto_Random return Crypto.Byte_Array;
   function Ristretto_Scalar_Random return Crypto.Byte_Array;
   function Ristretto_Scalar_Invert (S : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Ristretto_Scalar_Negate (S : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Ristretto_Scalar_Complement (S : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Ristretto_Scalar_Add (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Ristretto_Scalar_Sub (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Ristretto_Scalar_Mul (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Ristretto_Scalar_Reduce (S : Crypto.Byte_Array)
      return Crypto.Byte_Array;

   -------------------------------------------------------------
   --  Keccak-1600 (crypto_core_keccak1600_*): the raw permutation state, for
   --  constructing a custom Keccak/SHA-3 construction.
   -------------------------------------------------------------
   Keccak_State_Size : constant := 224;
   subtype Keccak_State is Crypto.State_Buffer (Keccak_State_Size);

   function Keccak_Init return Keccak_State;
   procedure Keccak_Xor_Bytes
     (State : in out Keccak_State; Data : Crypto.Byte_Array;
      Offset : Natural := 0);
   function Keccak_Extract_Bytes
     (State : Keccak_State; Length : Natural; Offset : Natural := 0)
      return Crypto.Byte_Array;
   procedure Keccak_Permute_24 (State : in out Keccak_State);
   procedure Keccak_Permute_12 (State : in out Keccak_State);

end Crypto.Core;
