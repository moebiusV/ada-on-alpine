pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Secretbox is

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

   procedure Check_Key (K : Crypto.Byte_Array) is
   begin
      if K'Length /= Key_Size then
         Fail ("key size");
      end if;
   end Check_Key;

   function C_Easy
     (C : System.Address; M : System.Address; M_Len : ULL;
      N, K : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_secretbox_easy";

   function C_Open_Easy
     (M : System.Address; C : System.Address; C_Len : ULL;
      N, K : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_secretbox_open_easy";

   function C_Detached
     (C, Mac, M : System.Address; M_Len : ULL;
      N, K : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_secretbox_detached";

   function C_Open_Detached
     (M, C, Mac : System.Address; C_Len : ULL;
      N, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_secretbox_open_detached";

   function Encrypt (Message, Nonce, Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      C : Crypto.Byte_Array (1 .. Mac_Size + Message'Length);
   begin
      Check_Nonce (Nonce);
      Check_Key (Key);
      if C_Easy (C (1)'Address, Addr (Message), ULL (Message'Length),
                 Addr (Nonce), Addr (Key)) /= 0
      then
         Fail ("secretbox encrypt failed");
      end if;
      return C;
   end Encrypt;

   function Decrypt (Ciphertext, Nonce, Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      M : Crypto.Byte_Array (1 .. Ciphertext'Length);
   begin
      Check_Nonce (Nonce);
      Check_Key (Key);
      if Ciphertext'Length < Mac_Size then
         Fail ("ciphertext size");
      end if;
      if C_Open_Easy (M (1)'Address, Addr (Ciphertext),
                      ULL (Ciphertext'Length), Addr (Nonce), Addr (Key)) /= 0
      then
         Fail ("secretbox decrypt failed");
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Ciphertext'Length - Mac_Size);
      begin
         Result := M (1 .. Ciphertext'Length - Mac_Size);
         return Result;
      end;
   end Decrypt;

   function Encrypt_Detached (Message, Nonce, Key : Crypto.Byte_Array)
      return Detached_Text
   is
      C : Crypto.Byte_Array (1 .. Message'Length);
      T : Detached_Text (Message'Length);
   begin
      Check_Nonce (Nonce);
      Check_Key (Key);
      if C_Detached (C (1)'Address, T.Mac (1)'Address, Addr (Message),
                     ULL (Message'Length), Addr (Nonce), Addr (Key)) /= 0
      then
         Fail ("secretbox detached encrypt failed");
      end if;
      T.Ciphertext := C;
      return T;
   end Encrypt_Detached;

   function Decrypt_Detached
     (Text : Detached_Text; Nonce, Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      M : Crypto.Byte_Array (1 .. Text.Ciphertext'Length);
   begin
      Check_Nonce (Nonce);
      Check_Key (Key);
      if C_Open_Detached (M (1)'Address, Addr (Text.Ciphertext),
                          Addr (Text.Mac), ULL (Text.Ciphertext'Length),
                          Addr (Nonce), Addr (Key)) /= 0
      then
         Fail ("secretbox detached decrypt failed");
      end if;
      return M;
   end Decrypt_Detached;

end Crypto.Secretbox;
