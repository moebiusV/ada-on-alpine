pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Core is

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

   function C_Salsa20 (Outp, Inp, K, C : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_salsa20";
   function C_Salsa2012 (Outp, Inp, K, C : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_salsa2012";
   function C_Salsa208 (Outp, Inp, K, C : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_salsa208";
   function C_Hsalsa20 (Outp, Inp, K, C : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_hsalsa20";
   function C_Hchacha20 (Outp, Inp, K, C : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_hchacha20";

   function C_Ed25519_Is_Valid_Point (P : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_is_valid_point";
   function C_Ed25519_Add (R, P, Q : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_ed25519_add";
   function C_Ed25519_Sub (R, P, Q : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_ed25519_sub";
   function C_Ed25519_From_Uniform (P, R : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_from_uniform";
   function C_Ed25519_From_Hash (P, H : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_from_hash";
   procedure C_Ed25519_Random (P : System.Address)
     with Import, Convention => C, External_Name => "crypto_core_ed25519_random";
   procedure C_Ed25519_Scalar_Random (R : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_scalar_random";
   function C_Ed25519_Scalar_Invert (Recip, S : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_scalar_invert";
   procedure C_Ed25519_Scalar_Negate (Neg, S : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_scalar_negate";
   procedure C_Ed25519_Scalar_Complement (Comp, S : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_scalar_complement";
   procedure C_Ed25519_Scalar_Add (Z, X, Y : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_scalar_add";
   procedure C_Ed25519_Scalar_Sub (Z, X, Y : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_scalar_sub";
   procedure C_Ed25519_Scalar_Mul (Z, X, Y : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_scalar_mul";
   procedure C_Ed25519_Scalar_Reduce (R, S : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ed25519_scalar_reduce";

   function C_Ristretto_Is_Valid_Point (P : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_is_valid_point";
   function C_Ristretto_Add (R, P, Q : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_ristretto255_add";
   function C_Ristretto_Sub (R, P, Q : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_core_ristretto255_sub";
   function C_Ristretto_From_Hash (P, H : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_from_hash";
   procedure C_Ristretto_Random (P : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_random";
   procedure C_Ristretto_Scalar_Random (R : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_scalar_random";
   function C_Ristretto_Scalar_Invert (Recip, S : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_scalar_invert";
   procedure C_Ristretto_Scalar_Negate (Neg, S : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_scalar_negate";
   procedure C_Ristretto_Scalar_Complement (Comp, S : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_scalar_complement";
   procedure C_Ristretto_Scalar_Add (Z, X, Y : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_scalar_add";
   procedure C_Ristretto_Scalar_Sub (Z, X, Y : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_scalar_sub";
   procedure C_Ristretto_Scalar_Mul (Z, X, Y : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_scalar_mul";
   procedure C_Ristretto_Scalar_Reduce (R, S : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_ristretto255_scalar_reduce";

   procedure C_Keccak_Init (State : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_keccak1600_init";
   procedure C_Keccak_Xor_Bytes
     (State, Inp : System.Address; Offset, Len : Interfaces.C.size_t)
     with Import, Convention => C,
          External_Name => "crypto_core_keccak1600_xor_bytes";
   procedure C_Keccak_Extract_Bytes
     (State, Outp : System.Address; Offset, Len : Interfaces.C.size_t)
     with Import, Convention => C,
          External_Name => "crypto_core_keccak1600_extract_bytes";
   procedure C_Keccak_Permute_24 (State : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_keccak1600_permute_24";
   procedure C_Keccak_Permute_12 (State : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_core_keccak1600_permute_12";

   procedure Check_Salsa (Inp, Key, Sigma : Crypto.Byte_Array) is
   begin
      if Inp'Length /= Salsa_Input_Size
        or else Key'Length /= Salsa_Key_Size
        or else Sigma'Length /= Salsa_Constant_Size
      then
         Fail ("salsa core size");
      end if;
   end Check_Salsa;

   function Salsa20 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      O : Crypto.Byte_Array (1 .. Salsa_Output_Size);
   begin
      Check_Salsa (Inp, Key, Sigma);
      if C_Salsa20 (O (1)'Address, Addr (Inp), Addr (Key), Addr (Sigma)) /= 0 then
         Fail ("salsa20 failed");
      end if;
      return O;
   end Salsa20;

   function Salsa2012 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      O : Crypto.Byte_Array (1 .. Salsa_Output_Size);
   begin
      Check_Salsa (Inp, Key, Sigma);
      if C_Salsa2012 (O (1)'Address, Addr (Inp), Addr (Key), Addr (Sigma)) /= 0 then
         Fail ("salsa2012 failed");
      end if;
      return O;
   end Salsa2012;

   function Salsa208 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      O : Crypto.Byte_Array (1 .. Salsa_Output_Size);
   begin
      Check_Salsa (Inp, Key, Sigma);
      if C_Salsa208 (O (1)'Address, Addr (Inp), Addr (Key), Addr (Sigma)) /= 0 then
         Fail ("salsa208 failed");
      end if;
      return O;
   end Salsa208;

   function HSalsa20 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      O : Crypto.Byte_Array (1 .. Short_Output_Size);
   begin
      Check_Salsa (Inp, Key, Sigma);
      if C_Hsalsa20 (O (1)'Address, Addr (Inp), Addr (Key), Addr (Sigma)) /= 0 then
         Fail ("hsalsa20 failed");
      end if;
      return O;
   end HSalsa20;

   function HChaCha20 (Inp, Key, Sigma : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      O : Crypto.Byte_Array (1 .. Short_Output_Size);
   begin
      Check_Salsa (Inp, Key, Sigma);
      if C_Hchacha20 (O (1)'Address, Addr (Inp), Addr (Key), Addr (Sigma)) /= 0 then
         Fail ("hchacha20 failed");
      end if;
      return O;
   end HChaCha20;

   function Ed25519_Is_Valid_Point (P : Crypto.Byte_Array) return Boolean is
   begin
      if P'Length /= Element_Size then
         Fail ("element size");
      end if;
      return C_Ed25519_Is_Valid_Point (Addr (P)) = 1;
   end Ed25519_Is_Valid_Point;

   function Ed25519_Add (P, Q : Crypto.Byte_Array) return Crypto.Byte_Array is
      R : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if P'Length /= Element_Size or else Q'Length /= Element_Size then
         Fail ("element size");
      end if;
      if C_Ed25519_Add (R (1)'Address, Addr (P), Addr (Q)) /= 0 then
         Fail ("ed25519 add failed");
      end if;
      return R;
   end Ed25519_Add;

   function Ed25519_Sub (P, Q : Crypto.Byte_Array) return Crypto.Byte_Array is
      R : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if P'Length /= Element_Size or else Q'Length /= Element_Size then
         Fail ("element size");
      end if;
      if C_Ed25519_Sub (R (1)'Address, Addr (P), Addr (Q)) /= 0 then
         Fail ("ed25519 sub failed");
      end if;
      return R;
   end Ed25519_Sub;

   function Ed25519_From_Uniform (R : Crypto.Byte_Array) return Crypto.Byte_Array is
      P : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if R'Length /= Uniform_Size then
         Fail ("uniform size");
      end if;
      if C_Ed25519_From_Uniform (P (1)'Address, Addr (R)) /= 0 then
         Fail ("ed25519 from_uniform failed");
      end if;
      return P;
   end Ed25519_From_Uniform;

   function Ed25519_From_Hash (H : Crypto.Byte_Array) return Crypto.Byte_Array is
      P : Crypto.Byte_Array (1 .. Element_Size);
   begin
      if H'Length /= Hash_Size then
         Fail ("hash size");
      end if;
      if C_Ed25519_From_Hash (P (1)'Address, Addr (H)) /= 0 then
         Fail ("ed25519 from_hash failed");
      end if;
      return P;
   end Ed25519_From_Hash;

   function Ed25519_Random return Crypto.Byte_Array is
      P : Crypto.Byte_Array (1 .. Element_Size);
   begin
      C_Ed25519_Random (P (1)'Address);
      return P;
   end Ed25519_Random;

   function Ed25519_Scalar_Random return Crypto.Byte_Array is
      R : Crypto.Byte_Array (1 .. Scalar_Size);
   begin
      C_Ed25519_Scalar_Random (R (1)'Address);
      return R;
   end Ed25519_Scalar_Random;

   function Ed25519_Scalar_Invert (S : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      R : Crypto.Byte_Array (1 .. Scalar_Size);
   begin
      if S'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      if C_Ed25519_Scalar_Invert (R (1)'Address, Addr (S)) /= 0 then
         Fail ("ed25519 scalar_invert failed");
      end if;
      return R;
   end Ed25519_Scalar_Invert;

   function Ed25519_Scalar_Negate (S : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      R : Crypto.Byte_Array (1 .. Scalar_Size);
   begin
      if S'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ed25519_Scalar_Negate (R (1)'Address, Addr (S));
      return R;
   end Ed25519_Scalar_Negate;

   function Ed25519_Scalar_Complement (S : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      R : Crypto.Byte_Array (1 .. Scalar_Size);
   begin
      if S'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ed25519_Scalar_Complement (R (1)'Address, Addr (S));
      return R;
   end Ed25519_Scalar_Complement;

   function Ed25519_Scalar_Add (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Z : Crypto.Byte_Array (1 .. Scalar_Size);
   begin
      if X'Length /= Scalar_Size or else Y'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ed25519_Scalar_Add (Z (1)'Address, Addr (X), Addr (Y));
      return Z;
   end Ed25519_Scalar_Add;

   function Ed25519_Scalar_Sub (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Z : Crypto.Byte_Array (1 .. Scalar_Size);
   begin
      if X'Length /= Scalar_Size or else Y'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ed25519_Scalar_Sub (Z (1)'Address, Addr (X), Addr (Y));
      return Z;
   end Ed25519_Scalar_Sub;

   function Ed25519_Scalar_Mul (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Z : Crypto.Byte_Array (1 .. Scalar_Size);
   begin
      if X'Length /= Scalar_Size or else Y'Length /= Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ed25519_Scalar_Mul (Z (1)'Address, Addr (X), Addr (Y));
      return Z;
   end Ed25519_Scalar_Mul;

   function Ed25519_Scalar_Reduce (S : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      R : Crypto.Byte_Array (1 .. Scalar_Size);
   begin
      if S'Length /= Nonreduced_Scalar_Size then
         Fail ("non-reduced scalar size");
      end if;
      C_Ed25519_Scalar_Reduce (R (1)'Address, Addr (S));
      return R;
   end Ed25519_Scalar_Reduce;

   function Ristretto_Is_Valid_Point (P : Crypto.Byte_Array) return Boolean is
   begin
      if P'Length /= Ristretto_Element_Size then
         Fail ("element size");
      end if;
      return C_Ristretto_Is_Valid_Point (Addr (P)) = 1;
   end Ristretto_Is_Valid_Point;

   function Ristretto_Add (P, Q : Crypto.Byte_Array) return Crypto.Byte_Array is
      R : Crypto.Byte_Array (1 .. Ristretto_Element_Size);
   begin
      if P'Length /= Ristretto_Element_Size
        or else Q'Length /= Ristretto_Element_Size
      then
         Fail ("element size");
      end if;
      if C_Ristretto_Add (R (1)'Address, Addr (P), Addr (Q)) /= 0 then
         Fail ("ristretto add failed");
      end if;
      return R;
   end Ristretto_Add;

   function Ristretto_Sub (P, Q : Crypto.Byte_Array) return Crypto.Byte_Array is
      R : Crypto.Byte_Array (1 .. Ristretto_Element_Size);
   begin
      if P'Length /= Ristretto_Element_Size
        or else Q'Length /= Ristretto_Element_Size
      then
         Fail ("element size");
      end if;
      if C_Ristretto_Sub (R (1)'Address, Addr (P), Addr (Q)) /= 0 then
         Fail ("ristretto sub failed");
      end if;
      return R;
   end Ristretto_Sub;

   function Ristretto_From_Hash (H : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      P : Crypto.Byte_Array (1 .. Ristretto_Element_Size);
   begin
      if H'Length /= Ristretto_Hash_Size then
         Fail ("hash size");
      end if;
      if C_Ristretto_From_Hash (P (1)'Address, Addr (H)) /= 0 then
         Fail ("ristretto from_hash failed");
      end if;
      return P;
   end Ristretto_From_Hash;

   function Ristretto_Random return Crypto.Byte_Array is
      P : Crypto.Byte_Array (1 .. Ristretto_Element_Size);
   begin
      C_Ristretto_Random (P (1)'Address);
      return P;
   end Ristretto_Random;

   function Ristretto_Scalar_Random return Crypto.Byte_Array is
      R : Crypto.Byte_Array (1 .. Ristretto_Scalar_Size);
   begin
      C_Ristretto_Scalar_Random (R (1)'Address);
      return R;
   end Ristretto_Scalar_Random;

   function Ristretto_Scalar_Invert (S : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      R : Crypto.Byte_Array (1 .. Ristretto_Scalar_Size);
   begin
      if S'Length /= Ristretto_Scalar_Size then
         Fail ("scalar size");
      end if;
      if C_Ristretto_Scalar_Invert (R (1)'Address, Addr (S)) /= 0 then
         Fail ("ristretto scalar_invert failed");
      end if;
      return R;
   end Ristretto_Scalar_Invert;

   function Ristretto_Scalar_Negate (S : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      R : Crypto.Byte_Array (1 .. Ristretto_Scalar_Size);
   begin
      if S'Length /= Ristretto_Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ristretto_Scalar_Negate (R (1)'Address, Addr (S));
      return R;
   end Ristretto_Scalar_Negate;

   function Ristretto_Scalar_Complement (S : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      R : Crypto.Byte_Array (1 .. Ristretto_Scalar_Size);
   begin
      if S'Length /= Ristretto_Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ristretto_Scalar_Complement (R (1)'Address, Addr (S));
      return R;
   end Ristretto_Scalar_Complement;

   function Ristretto_Scalar_Add (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Z : Crypto.Byte_Array (1 .. Ristretto_Scalar_Size);
   begin
      if X'Length /= Ristretto_Scalar_Size or else Y'Length /= Ristretto_Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ristretto_Scalar_Add (Z (1)'Address, Addr (X), Addr (Y));
      return Z;
   end Ristretto_Scalar_Add;

   function Ristretto_Scalar_Sub (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Z : Crypto.Byte_Array (1 .. Ristretto_Scalar_Size);
   begin
      if X'Length /= Ristretto_Scalar_Size or else Y'Length /= Ristretto_Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ristretto_Scalar_Sub (Z (1)'Address, Addr (X), Addr (Y));
      return Z;
   end Ristretto_Scalar_Sub;

   function Ristretto_Scalar_Mul (X, Y : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Z : Crypto.Byte_Array (1 .. Ristretto_Scalar_Size);
   begin
      if X'Length /= Ristretto_Scalar_Size or else Y'Length /= Ristretto_Scalar_Size then
         Fail ("scalar size");
      end if;
      C_Ristretto_Scalar_Mul (Z (1)'Address, Addr (X), Addr (Y));
      return Z;
   end Ristretto_Scalar_Mul;

   function Ristretto_Scalar_Reduce (S : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      R : Crypto.Byte_Array (1 .. Ristretto_Scalar_Size);
   begin
      if S'Length /= Ristretto_Nonreduced_Scalar_Size then
         Fail ("non-reduced scalar size");
      end if;
      C_Ristretto_Scalar_Reduce (R (1)'Address, Addr (S));
      return R;
   end Ristretto_Scalar_Reduce;

   function Keccak_Init return Keccak_State is
      S : Keccak_State;
   begin
      C_Keccak_Init (S.Data (1)'Address);
      return S;
   end Keccak_Init;

   procedure Keccak_Xor_Bytes
     (State : in out Keccak_State; Data : Crypto.Byte_Array;
      Offset : Natural := 0) is
   begin
      C_Keccak_Xor_Bytes (State.Data (1)'Address, Addr (Data),
                          Interfaces.C.size_t (Offset),
                          Interfaces.C.size_t (Data'Length));
   end Keccak_Xor_Bytes;

   function Keccak_Extract_Bytes
     (State : Keccak_State; Length : Natural; Offset : Natural := 0)
      return Crypto.Byte_Array
   is
      O : Crypto.Byte_Array (1 .. Length);
   begin
      C_Keccak_Extract_Bytes (State.Data (1)'Address, O (1)'Address,
                              Interfaces.C.size_t (Offset),
                              Interfaces.C.size_t (Length));
      return O;
   end Keccak_Extract_Bytes;

   procedure Keccak_Permute_24 (State : in out Keccak_State) is
   begin
      C_Keccak_Permute_24 (State.Data (1)'Address);
   end Keccak_Permute_24;

   procedure Keccak_Permute_12 (State : in out Keccak_State) is
   begin
      C_Keccak_Permute_12 (State.Data (1)'Address);
   end Keccak_Permute_12;

end Crypto.Core;
