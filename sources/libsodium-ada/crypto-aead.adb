pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Aead is

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

   function Enc_Chacha20_Ietf
     (C, Mac, Mac_Len, M : System.Address; M_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Nsec, Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_chacha20poly1305_ietf_encrypt_detached";

   function Dec_Chacha20_Ietf
     (M, Nsec, C : System.Address; C_Len : ULL; Mac : System.Address;
      Ad : System.Address; Ad_Len : ULL;
      Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_chacha20poly1305_ietf_decrypt_detached";

   function Enc_Xchacha20_Ietf
     (C, Mac, Mac_Len, M : System.Address; M_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Nsec, Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_xchacha20poly1305_ietf_encrypt_detached";

   function Dec_Xchacha20_Ietf
     (M, Nsec, C : System.Address; C_Len : ULL; Mac : System.Address;
      Ad : System.Address; Ad_Len : ULL;
      Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_xchacha20poly1305_ietf_decrypt_detached";

   function Enc_Chacha20
     (C, Mac, Mac_Len, M : System.Address; M_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Nsec, Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_chacha20poly1305_encrypt_detached";

   function Dec_Chacha20
     (M, Nsec, C : System.Address; C_Len : ULL; Mac : System.Address;
      Ad : System.Address; Ad_Len : ULL;
      Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_chacha20poly1305_decrypt_detached";

   function Enc_Aes256gcm
     (C, Mac, Mac_Len, M : System.Address; M_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Nsec, Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_aes256gcm_encrypt_detached";

   function Dec_Aes256gcm
     (M, Nsec, C : System.Address; C_Len : ULL; Mac : System.Address;
      Ad : System.Address; Ad_Len : ULL;
      Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_aes256gcm_decrypt_detached";

   function Enc_C_Chacha20_Ietf
     (C, C_Len, M : System.Address; M_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Nsec, Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_chacha20poly1305_ietf_encrypt";

   function Dec_C_Chacha20_Ietf
     (M, M_Len, Nsec, C : System.Address; C_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_chacha20poly1305_ietf_decrypt";

   function Enc_C_Xchacha20_Ietf
     (C, C_Len, M : System.Address; M_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Nsec, Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_xchacha20poly1305_ietf_encrypt";

   function Dec_C_Xchacha20_Ietf
     (M, M_Len, Nsec, C : System.Address; C_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_xchacha20poly1305_ietf_decrypt";

   function Enc_C_Chacha20
     (C, C_Len, M : System.Address; M_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Nsec, Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_chacha20poly1305_encrypt";

   function Dec_C_Chacha20
     (M, M_Len, Nsec, C : System.Address; C_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_chacha20poly1305_decrypt";

   function Enc_C_Aes256gcm
     (C, C_Len, M : System.Address; M_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Nsec, Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_aes256gcm_encrypt";

   function Dec_C_Aes256gcm
     (M, M_Len, Nsec, C : System.Address; C_Len : ULL;
      Ad : System.Address; Ad_Len : ULL;
      Npub, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_aes256gcm_decrypt";

   function C_Aes256gcm_Available return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_aead_aes256gcm_is_available";

   function Aes256gcm_Available return Boolean is
     (C_Aes256gcm_Available /= 0);

   function Seal
     (Message : Crypto.Byte_Array;
      Nonce, Key, Aad : Crypto.Byte_Array;
      Kind : Aead_Kind) return Crypto.Sealed_Text
   is
      pragma Warnings (Off, "could be declared constant");
      Cipher  : aliased Crypto.Byte_Array (Message'Range) := [others => 0];
      Tag     : aliased Crypto.Byte_Array (1 .. Crypto.Tag_Size) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      Mac_Len : aliased ULL := ULL (Crypto.Tag_Size);
      Rc      : Interfaces.C.int;
   begin
      if Key'Length /= 32 or else Nonce'Length /= Nonce_Size (Kind) then
         Fail ("key or nonce size");
      end if;
      case Kind is
         when Chacha20_Ietf  => Rc := Enc_Chacha20_Ietf (Addr (Cipher), Addr (Tag), Mac_Len'Address, Addr (Message), ULL (Message'Length), Addr (Aad), ULL (Aad'Length), System.Null_Address, Addr (Nonce), Addr (Key));
         when Xchacha20_Ietf => Rc := Enc_Xchacha20_Ietf (Addr (Cipher), Addr (Tag), Mac_Len'Address, Addr (Message), ULL (Message'Length), Addr (Aad), ULL (Aad'Length), System.Null_Address, Addr (Nonce), Addr (Key));
         when Chacha20       => Rc := Enc_Chacha20 (Addr (Cipher), Addr (Tag), Mac_Len'Address, Addr (Message), ULL (Message'Length), Addr (Aad), ULL (Aad'Length), System.Null_Address, Addr (Nonce), Addr (Key));
         when Aes256gcm      => Rc := Enc_Aes256gcm (Addr (Cipher), Addr (Tag), Mac_Len'Address, Addr (Message), ULL (Message'Length), Addr (Aad), ULL (Aad'Length), System.Null_Address, Addr (Nonce), Addr (Key));
      end case;
      if Rc /= 0 then
         Fail ("aead encrypt failed");
      end if;
      return Crypto.Sealed_Text'
        (Length => Cipher'Length, Ciphertext => Cipher, Tag => Tag);
   end Seal;

   function Open
     (Key, Nonce, Aad : Crypto.Byte_Array;
      Text : Crypto.Sealed_Text;
      Kind : Aead_Kind) return Crypto.Byte_Array
   is
      pragma Warnings (Off, "could be declared constant");
      Plain : aliased Crypto.Byte_Array (Text.Ciphertext'Range) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      Rc    : Interfaces.C.int;
   begin
      if Key'Length /= 32 or else Nonce'Length /= Nonce_Size (Kind) then
         Fail ("key or nonce size");
      end if;
      case Kind is
         when Chacha20_Ietf  => Rc := Dec_Chacha20_Ietf (Addr (Plain), System.Null_Address, Addr (Text.Ciphertext), ULL (Text.Ciphertext'Length), Addr (Text.Tag), Addr (Aad), ULL (Aad'Length), Addr (Nonce), Addr (Key));
         when Xchacha20_Ietf => Rc := Dec_Xchacha20_Ietf (Addr (Plain), System.Null_Address, Addr (Text.Ciphertext), ULL (Text.Ciphertext'Length), Addr (Text.Tag), Addr (Aad), ULL (Aad'Length), Addr (Nonce), Addr (Key));
         when Chacha20       => Rc := Dec_Chacha20 (Addr (Plain), System.Null_Address, Addr (Text.Ciphertext), ULL (Text.Ciphertext'Length), Addr (Text.Tag), Addr (Aad), ULL (Aad'Length), Addr (Nonce), Addr (Key));
         when Aes256gcm      => Rc := Dec_Aes256gcm (Addr (Plain), System.Null_Address, Addr (Text.Ciphertext), ULL (Text.Ciphertext'Length), Addr (Text.Tag), Addr (Aad), ULL (Aad'Length), Addr (Nonce), Addr (Key));
      end case;
      if Rc /= 0 then
         Fail ("aead decrypt failed");
      end if;
      return Plain;
   end Open;

   function Seal_Combined
     (Message : Crypto.Byte_Array;
      Nonce, Key, Aad : Crypto.Byte_Array;
      Kind : Aead_Kind) return Crypto.Byte_Array
   is
      pragma Warnings (Off, "could be declared constant");
      C     : aliased Crypto.Byte_Array
                (1 .. Message'Length + Crypto.Tag_Size) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      C_Len : aliased ULL := 0;
      Rc    : Interfaces.C.int;
   begin
      if Key'Length /= 32 or else Nonce'Length /= Nonce_Size (Kind) then
         Fail ("key or nonce size");
      end if;
      case Kind is
         when Chacha20_Ietf  => Rc := Enc_C_Chacha20_Ietf (Addr (C), C_Len'Address, Addr (Message), ULL (Message'Length), Addr (Aad), ULL (Aad'Length), System.Null_Address, Addr (Nonce), Addr (Key));
         when Xchacha20_Ietf => Rc := Enc_C_Xchacha20_Ietf (Addr (C), C_Len'Address, Addr (Message), ULL (Message'Length), Addr (Aad), ULL (Aad'Length), System.Null_Address, Addr (Nonce), Addr (Key));
         when Chacha20       => Rc := Enc_C_Chacha20 (Addr (C), C_Len'Address, Addr (Message), ULL (Message'Length), Addr (Aad), ULL (Aad'Length), System.Null_Address, Addr (Nonce), Addr (Key));
         when Aes256gcm      => Rc := Enc_C_Aes256gcm (Addr (C), C_Len'Address, Addr (Message), ULL (Message'Length), Addr (Aad), ULL (Aad'Length), System.Null_Address, Addr (Nonce), Addr (Key));
      end case;
      if Rc /= 0 then
         Fail ("aead encrypt failed");
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Natural (C_Len));
      begin
         Result := C (1 .. Natural (C_Len));
         return Result;
      end;
   end Seal_Combined;

   function Open_Combined
     (Key, Nonce, Aad : Crypto.Byte_Array;
      Ciphertext : Crypto.Byte_Array;
      Kind : Aead_Kind) return Crypto.Byte_Array
   is
      pragma Warnings (Off, "could be declared constant");
      M     : aliased Crypto.Byte_Array (1 .. Ciphertext'Length) :=
                [others => 0];
      pragma Warnings (On, "could be declared constant");
      M_Len : aliased ULL := 0;
      Rc    : Interfaces.C.int;
   begin
      if Key'Length /= 32 or else Nonce'Length /= Nonce_Size (Kind) then
         Fail ("key or nonce size");
      end if;
      if Ciphertext'Length < Crypto.Tag_Size then
         Fail ("ciphertext too short");
      end if;
      case Kind is
         when Chacha20_Ietf  => Rc := Dec_C_Chacha20_Ietf (Addr (M), M_Len'Address, System.Null_Address, Addr (Ciphertext), ULL (Ciphertext'Length), Addr (Aad), ULL (Aad'Length), Addr (Nonce), Addr (Key));
         when Xchacha20_Ietf => Rc := Dec_C_Xchacha20_Ietf (Addr (M), M_Len'Address, System.Null_Address, Addr (Ciphertext), ULL (Ciphertext'Length), Addr (Aad), ULL (Aad'Length), Addr (Nonce), Addr (Key));
         when Chacha20       => Rc := Dec_C_Chacha20 (Addr (M), M_Len'Address, System.Null_Address, Addr (Ciphertext), ULL (Ciphertext'Length), Addr (Aad), ULL (Aad'Length), Addr (Nonce), Addr (Key));
         when Aes256gcm      => Rc := Dec_C_Aes256gcm (Addr (M), M_Len'Address, System.Null_Address, Addr (Ciphertext), ULL (Ciphertext'Length), Addr (Aad), ULL (Aad'Length), Addr (Nonce), Addr (Key));
      end case;
      if Rc /= 0 then
         Fail ("aead decrypt failed");
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Natural (M_Len));
      begin
         Result := M (1 .. Natural (M_Len));
         return Result;
      end;
   end Open_Combined;

end Crypto.Aead;
