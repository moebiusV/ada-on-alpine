pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto is

   use type Ada.Streams.Stream_Element;
   use type Interfaces.C.int;

   --  64-bit unsigned, matching libsodium's unsigned long long lengths.
   type ULL is mod 2 ** 64;
   pragma Convention (C, ULL);

   procedure Randombytes_Buf (Buf : System.Address; Size : Interfaces.C.size_t)
     with Import, Convention => C, External_Name => "randombytes_buf";

   function Crypto_Hash_Sha256
     (Digest  : System.Address;
      Msg     : System.Address;
      Msg_Len : ULL)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha256";

   function Crypto_Aead_Chacha20poly1305_Ietf_Encrypt_Detached
     (C       : System.Address;
      Mac     : System.Address;
      Mac_Len : System.Address;
      M       : System.Address;
      M_Len   : ULL;
      Ad      : System.Address;
      Ad_Len  : ULL;
      Nsec    : System.Address;
      Npub    : System.Address;
      K       : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name =>
            "crypto_aead_chacha20poly1305_ietf_encrypt_detached";

   function Crypto_Aead_Chacha20poly1305_Ietf_Decrypt_Detached
     (M      : System.Address;
      Nsec   : System.Address;
      C      : System.Address;
      C_Len  : ULL;
      Mac    : System.Address;
      Ad     : System.Address;
      Ad_Len : ULL;
      Npub   : System.Address;
      K      : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name =>
            "crypto_aead_chacha20poly1305_ietf_decrypt_detached";

   --  Address of a byte array, or a null pointer when empty.
   function Addr (B : Byte_Array) return System.Address is
   begin
      if B'Length = 0 then
         return System.Null_Address;
      end if;
      return B (B'First)'Address;
   end Addr;

   function Random (N : Natural) return Byte_Array is
      Result : Byte_Array (1 .. N);
   begin
      if N > 0 then
         Randombytes_Buf
           (Result (Result'First)'Address, Interfaces.C.size_t (N));
      end if;
      return Result;
   end Random;

   --  RFC 2104 HMAC-SHA256, composed over libsodium's SHA-256 so keys of any
   --  length follow the standard (crypto_auth_hmacsha256 fixes the key at 32
   --  bytes).  The cryptographic primitive is the maintained SHA-256; only the
   --  pad-XOR-and-hash composition is spelled out here.
   function Hmac_Sha256
     (Key  : Byte_Array;
      Data : Byte_Array) return Byte_Array
   is
      Block_Size : constant := 64;
      --  Buffers the C library fills in are marked `aliased`: a statically
      --  initialised object Ada never assigns would otherwise be folded into
      --  read-only storage, and the C write through 'Address then faults.
      Key_Norm   : aliased Byte_Array (1 .. Block_Size) := [others => 0];
      pragma Warnings (Off, "could be declared constant");
      Inner_Hash : aliased Byte_Array (1 .. Hmac_Size) := [others => 0];
      Result     : aliased Byte_Array (1 .. Hmac_Size) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      Inner      : Byte_Array (1 .. Block_Size + Data'Length);
      Outer      : Byte_Array (1 .. Block_Size + Hmac_Size);
      Rc         : Interfaces.C.int;
   begin
      if Key'Length > Block_Size then
         Rc := Crypto_Hash_Sha256
           (Key_Norm (1)'Address, Addr (Key), ULL (Key'Length));
         if Rc /= 0 then
            raise Crypto_Error with "sha256 key-hash failed";
         end if;
      elsif Key'Length > 0 then
         Key_Norm (1 .. Key'Length) := Key;
      end if;

      for I in 1 .. Block_Size loop
         Inner (I) := Key_Norm (I) xor 16#36#;
      end loop;
      Inner (Block_Size + 1 .. Inner'Last) := Data;
      Rc := Crypto_Hash_Sha256
        (Inner_Hash (1)'Address, Inner (1)'Address, ULL (Inner'Length));
      if Rc /= 0 then
         raise Crypto_Error with "sha256 inner-hash failed";
      end if;

      for I in 1 .. Block_Size loop
         Outer (I) := Key_Norm (I) xor 16#5c#;
      end loop;
      Outer (Block_Size + 1 .. Outer'Last) := Inner_Hash;
      Rc := Crypto_Hash_Sha256
        (Result (1)'Address, Outer (1)'Address, ULL (Outer'Length));
      if Rc /= 0 then
         raise Crypto_Error with "sha256 outer-hash failed";
      end if;

      return Result;
   end Hmac_Sha256;

   function Seal
     (Key, Nonce, Aad, Plaintext : Byte_Array) return Sealed_Text
   is
      --  Cipher and Tag are written by the C call through their address, so
      --  they are aliased (see Hmac_Sha256 above) and GNAT's "could be
      --  constant" flow warning is a false positive.
      pragma Warnings (Off, "could be declared constant");
      Cipher  : aliased Byte_Array (Plaintext'Range) := [others => 0];
      Tag     : aliased Byte_Array (1 .. Tag_Size) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      Mac_Len : aliased ULL := ULL (Tag_Size);
      Rc      : Interfaces.C.int;
   begin
      if Key'Length /= Key_Size or else Nonce'Length /= Nonce_Size then
         raise Crypto_Error with "bad key or nonce size";
      end if;
      Rc := Crypto_Aead_Chacha20poly1305_Ietf_Encrypt_Detached
        (Addr (Cipher), Addr (Tag), Mac_Len'Address,
         Addr (Plaintext), ULL (Plaintext'Length),
         Addr (Aad), ULL (Aad'Length),
         System.Null_Address, Addr (Nonce), Addr (Key));
      if Rc /= 0 then
         raise Crypto_Error with "aead encrypt failed";
      end if;
      return Sealed_Text'
        (Length => Cipher'Length, Ciphertext => Cipher, Tag => Tag);
   end Seal;

   function Open
     (Key, Nonce, Aad : Byte_Array;
      Text            : Sealed_Text) return Byte_Array
   is
      pragma Warnings (Off, "could be declared constant");
      Plain : aliased Byte_Array (Text.Ciphertext'Range) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      Rc    : Interfaces.C.int;
   begin
      if Key'Length /= Key_Size or else Nonce'Length /= Nonce_Size then
         raise Crypto_Error with "bad key or nonce size";
      end if;
      Rc := Crypto_Aead_Chacha20poly1305_Ietf_Decrypt_Detached
        (Addr (Plain), System.Null_Address,
         Addr (Text.Ciphertext), ULL (Text.Ciphertext'Length),
         Addr (Text.Tag),
         Addr (Aad), ULL (Aad'Length),
         Addr (Nonce), Addr (Key));
      if Rc /= 0 then
         raise Crypto_Error with "authentication failed";
      end if;
      return Plain;
   end Open;

end Crypto;
