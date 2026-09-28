pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Kem is

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

   function C_Mlkem_Keypair (Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_kem_mlkem768_keypair";

   function C_Mlkem_Seed_Keypair
     (Pk, Sk, Seed : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kem_mlkem768_seed_keypair";

   function C_Mlkem_Enc (Ct, Ss, Pk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_kem_mlkem768_enc";

   function C_Mlkem_Dec (Ss, Ct, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_kem_mlkem768_dec";

   function C_Xwing_Keypair (Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_kem_xwing_keypair";

   function C_Xwing_Seed_Keypair
     (Pk, Sk, Seed : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_kem_xwing_seed_keypair";

   function C_Xwing_Enc (Ct, Ss, Pk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_kem_xwing_enc";

   function C_Xwing_Dec (Ss, Ct, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_kem_xwing_dec";

   function Keygen (A : Algorithm) return Keypair is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size (A));
      Sk : Crypto.Byte_Array (1 .. Secret_Key_Size (A));
      Rc : Interfaces.C.int;
   begin
      case A is
         when Mlkem768 =>
            Rc := C_Mlkem_Keypair (Pk (1)'Address, Sk (1)'Address);
         when Xwing =>
            Rc := C_Xwing_Keypair (Pk (1)'Address, Sk (1)'Address);
      end case;
      if Rc /= 0 then
         Fail ("kem keygen failed");
      end if;
      return (Public_Size => Public_Key_Size (A),
              Secret_Size => Secret_Key_Size (A),
              Public => Pk, Secret => Sk);
   end Keygen;

   function Seed_Keypair (Seed : Crypto.Byte_Array; A : Algorithm)
      return Keypair
   is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size (A));
      Sk : Crypto.Byte_Array (1 .. Secret_Key_Size (A));
      Rc : Interfaces.C.int;
   begin
      if Seed'Length /= Seed_Size (A) then
         Fail ("seed size");
      end if;
      case A is
         when Mlkem768 =>
            Rc := C_Mlkem_Seed_Keypair
              (Pk (1)'Address, Sk (1)'Address, Addr (Seed));
         when Xwing =>
            Rc := C_Xwing_Seed_Keypair
              (Pk (1)'Address, Sk (1)'Address, Addr (Seed));
      end case;
      if Rc /= 0 then
         Fail ("kem seed keypair failed");
      end if;
      return (Public_Size => Public_Key_Size (A),
              Secret_Size => Secret_Key_Size (A),
              Public => Pk, Secret => Sk);
   end Seed_Keypair;

   function Encapsulate (Public_Key : Crypto.Byte_Array; A : Algorithm)
      return Sealed
   is
      Ct : Crypto.Byte_Array (1 .. Ciphertext_Size (A));
      Ss : Crypto.Byte_Array (1 .. Shared_Secret_Size);
      Rc : Interfaces.C.int;
   begin
      if Public_Key'Length /= Public_Key_Size (A) then
         Fail ("public key size");
      end if;
      case A is
         when Mlkem768 =>
            Rc := C_Mlkem_Enc (Ct (1)'Address, Ss (1)'Address, Addr (Public_Key));
         when Xwing =>
            Rc := C_Xwing_Enc (Ct (1)'Address, Ss (1)'Address, Addr (Public_Key));
      end case;
      if Rc /= 0 then
         Fail ("kem encapsulate failed");
      end if;
      return (Ct_Size => Ciphertext_Size (A),
              Ciphertext => Ct, Shared => Ss);
   end Encapsulate;

   function Decapsulate
     (Ciphertext, Secret_Key : Crypto.Byte_Array; A : Algorithm)
      return Crypto.Byte_Array
   is
      Ss : Crypto.Byte_Array (1 .. Shared_Secret_Size);
      Rc : Interfaces.C.int;
   begin
      if Ciphertext'Length /= Ciphertext_Size (A)
        or else Secret_Key'Length /= Secret_Key_Size (A)
      then
         Fail ("ciphertext or secret key size");
      end if;
      case A is
         when Mlkem768 =>
            Rc := C_Mlkem_Dec
              (Ss (1)'Address, Addr (Ciphertext), Addr (Secret_Key));
         when Xwing =>
            Rc := C_Xwing_Dec
              (Ss (1)'Address, Addr (Ciphertext), Addr (Secret_Key));
      end case;
      if Rc /= 0 then
         Fail ("kem decapsulate failed");
      end if;
      return Ss;
   end Decapsulate;

end Crypto.Kem;
