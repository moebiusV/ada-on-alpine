pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Box is

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

   procedure Check_Nonce (N : Crypto.Byte_Array) is
   begin
      if N'Length /= Nonce_Size then
         Fail ("nonce size");
      end if;
   end Check_Nonce;

   function C_Keypair (Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_keypair";

   function C_Seed_Keypair
     (Pk, Sk, Seed : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_seed_keypair";

   function C_Easy
     (C : System.Address; M : System.Address; M_Len : ULL;
      N, Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_easy";

   function C_Open_Easy
     (M : System.Address; C : System.Address; C_Len : ULL;
      N, Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_open_easy";

   function C_Detached
     (C, Mac, M : System.Address; M_Len : ULL;
      N, Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_detached";

   function C_Open_Detached
     (M, C, Mac : System.Address; C_Len : ULL;
      N, Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_open_detached";

   function C_Beforenm
     (K, Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_beforenm";

   function C_Easy_Afternm
     (C : System.Address; M : System.Address; M_Len : ULL;
      N, K : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_easy_afternm";

   function C_Open_Easy_Afternm
     (M : System.Address; C : System.Address; C_Len : ULL;
      N, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_box_open_easy_afternm";

   function C_Seal
     (C : System.Address; M : System.Address; M_Len : ULL;
      Pk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_seal";

   function C_Seal_Open
     (M : System.Address; C : System.Address; C_Len : ULL;
      Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_box_seal_open";

   function Keygen return Keypair is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size);
      Sk : Crypto.Byte_Array (1 .. Secret_Key_Size);
   begin
      if C_Keypair (Pk (1)'Address, Sk (1)'Address) /= 0 then
         Fail ("box keygen failed");
      end if;
      return (Public => Pk, Secret => Sk);
   end Keygen;

   function Seed_Keypair (Seed : Crypto.Byte_Array) return Keypair is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size);
      Sk : Crypto.Byte_Array (1 .. Secret_Key_Size);
   begin
      if Seed'Length /= Seed_Size then
         Fail ("seed size");
      end if;
      if C_Seed_Keypair (Pk (1)'Address, Sk (1)'Address, Addr (Seed)) /= 0 then
         Fail ("box seed keypair failed");
      end if;
      return (Public => Pk, Secret => Sk);
   end Seed_Keypair;

   function Encrypt
     (Message, Nonce, Public_Key, Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      C : Crypto.Byte_Array (1 .. Mac_Size + Message'Length);
   begin
      Check_Nonce (Nonce);
      if Public_Key'Length /= Public_Key_Size
        or else Secret_Key'Length /= Secret_Key_Size
      then
         Fail ("key size");
      end if;
      if C_Easy
        (C (1)'Address, Addr (Message), ULL (Message'Length),
         Addr (Nonce), Addr (Public_Key), Addr (Secret_Key)) /= 0
      then
         Fail ("box encrypt failed");
      end if;
      return C;
   end Encrypt;

   function Decrypt
     (Ciphertext, Nonce, Public_Key, Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      M : Crypto.Byte_Array (1 .. Ciphertext'Length);
   begin
      Check_Nonce (Nonce);
      if Public_Key'Length /= Public_Key_Size
        or else Secret_Key'Length /= Secret_Key_Size
        or else Ciphertext'Length < Mac_Size
      then
         Fail ("key or ciphertext size");
      end if;
      if C_Open_Easy
        (M (1)'Address, Addr (Ciphertext), ULL (Ciphertext'Length),
         Addr (Nonce), Addr (Public_Key), Addr (Secret_Key)) /= 0
      then
         Fail ("box decrypt failed");
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Ciphertext'Length - Mac_Size);
      begin
         Result := M (1 .. Ciphertext'Length - Mac_Size);
         return Result;
      end;
   end Decrypt;

   function Encrypt_Detached
     (Message, Nonce, Public_Key, Secret_Key : Crypto.Byte_Array)
      return Detached_Text
   is
      C : Crypto.Byte_Array (1 .. Message'Length);
      T : Detached_Text (Message'Length);
   begin
      Check_Nonce (Nonce);
      if Public_Key'Length /= Public_Key_Size
        or else Secret_Key'Length /= Secret_Key_Size
      then
         Fail ("key size");
      end if;
      if C_Detached
        (C (1)'Address, T.Mac (1)'Address, Addr (Message),
         ULL (Message'Length), Addr (Nonce), Addr (Public_Key),
         Addr (Secret_Key)) /= 0
      then
         Fail ("box detached encrypt failed");
      end if;
      T.Ciphertext := C;
      return T;
   end Encrypt_Detached;

   function Decrypt_Detached
     (Text       : Detached_Text;
      Nonce      : Crypto.Byte_Array;
      Public_Key : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array
   is
      M : Crypto.Byte_Array (1 .. Text.Ciphertext'Length);
   begin
      Check_Nonce (Nonce);
      if Public_Key'Length /= Public_Key_Size
        or else Secret_Key'Length /= Secret_Key_Size
      then
         Fail ("key size");
      end if;
      if C_Open_Detached
        (M (1)'Address, Addr (Text.Ciphertext), Addr (Text.Mac),
         ULL (Text.Ciphertext'Length), Addr (Nonce), Addr (Public_Key),
         Addr (Secret_Key)) /= 0
      then
         Fail ("box detached decrypt failed");
      end if;
      return M;
   end Decrypt_Detached;

   function Before_Shared (Public_Key, Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      K : Crypto.Byte_Array (1 .. Before_Shared_Key_Size);
   begin
      if Public_Key'Length /= Public_Key_Size
        or else Secret_Key'Length /= Secret_Key_Size
      then
         Fail ("key size");
      end if;
      if C_Beforenm (K (1)'Address, Addr (Public_Key), Addr (Secret_Key)) /= 0
      then
         Fail ("box beforenm failed");
      end if;
      return K;
   end Before_Shared;

   function Encrypt_After_Shared (Message, Nonce, Shared_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      C : Crypto.Byte_Array (1 .. Mac_Size + Message'Length);
   begin
      Check_Nonce (Nonce);
      if Shared_Key'Length /= Before_Shared_Key_Size then
         Fail ("shared key size");
      end if;
      if C_Easy_Afternm
        (C (1)'Address, Addr (Message), ULL (Message'Length),
         Addr (Nonce), Addr (Shared_Key)) /= 0
      then
         Fail ("box afternm encrypt failed");
      end if;
      return C;
   end Encrypt_After_Shared;

   function Decrypt_After_Shared
     (Ciphertext, Nonce, Shared_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      M : Crypto.Byte_Array (1 .. Ciphertext'Length);
   begin
      Check_Nonce (Nonce);
      if Shared_Key'Length /= Before_Shared_Key_Size
        or else Ciphertext'Length < Mac_Size
      then
         Fail ("shared key or ciphertext size");
      end if;
      if C_Open_Easy_Afternm
        (M (1)'Address, Addr (Ciphertext), ULL (Ciphertext'Length),
         Addr (Nonce), Addr (Shared_Key)) /= 0
      then
         Fail ("box afternm decrypt failed");
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Ciphertext'Length - Mac_Size);
      begin
         Result := M (1 .. Ciphertext'Length - Mac_Size);
         return Result;
      end;
   end Decrypt_After_Shared;

   function Seal (Message, Public_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      C : Crypto.Byte_Array (1 .. Seal_Size + Message'Length);
   begin
      if Public_Key'Length /= Public_Key_Size then
         Fail ("public key size");
      end if;
      if C_Seal (C (1)'Address, Addr (Message), ULL (Message'Length),
                 Addr (Public_Key)) /= 0
      then
         Fail ("box seal failed");
      end if;
      return C;
   end Seal;

   function Seal_Open (Ciphertext, Public_Key, Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      M : Crypto.Byte_Array (1 .. Ciphertext'Length);
   begin
      if Public_Key'Length /= Public_Key_Size
        or else Secret_Key'Length /= Secret_Key_Size
        or else Ciphertext'Length < Seal_Size
      then
         Fail ("key or ciphertext size");
      end if;
      if C_Seal_Open
        (M (1)'Address, Addr (Ciphertext), ULL (Ciphertext'Length),
         Addr (Public_Key), Addr (Secret_Key)) /= 0
      then
         Fail ("box seal open failed");
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Ciphertext'Length - Seal_Size);
      begin
         Result := M (1 .. Ciphertext'Length - Seal_Size);
         return Result;
      end;
   end Seal_Open;

end Crypto.Box;
