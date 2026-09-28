pragma Ada_2022;


--  Authenticated encryption with associated data (crypto_aead_*), across the
--  four primitives libsodium ships.  Each Kind has its own nonce length; the
--  key is 32 bytes and the tag 16 (Crypto.Tag_Size) throughout.
package Crypto.Aead is

   type Aead_Kind is (Chacha20_Ietf, Xchacha20_Ietf, Chacha20, Aes256gcm);

   Key_Size : constant := 32;
   function Nonce_Size (Kind : Aead_Kind) return Natural is
     (case Kind is
        when Xchacha20_Ietf => 24,
        when Chacha20       => 8,
        when others         => 12);

   --  AES-256-GCM needs the AES-NI instructions; on a CPU without them this
   --  is False and Seal/Open with Aes256gcm will fail.  Probe before use.
   function Aes256gcm_Available return Boolean;

   function Seal
     (Message : Crypto.Byte_Array;
      Nonce, Key, Aad : Crypto.Byte_Array;
      Kind : Aead_Kind) return Crypto.Sealed_Text;
   function Open
     (Key, Nonce, Aad : Crypto.Byte_Array;
      Text : Crypto.Sealed_Text;
      Kind : Aead_Kind) return Crypto.Byte_Array;

   --  Combined-mode (crypto_aead_*_encrypt/decrypt): the ciphertext and tag
   --  concatenated into one buffer, Ciphertext || Tag.  Seal_Combined returns
   --  Message'Length + Crypto.Tag_Size bytes; Open_Combined recovers the
   --  plaintext from that buffer, raising Crypto_Error on failure.
   function Seal_Combined
     (Message : Crypto.Byte_Array;
      Nonce, Key, Aad : Crypto.Byte_Array;
      Kind : Aead_Kind) return Crypto.Byte_Array;
   function Open_Combined
     (Key, Nonce, Aad : Crypto.Byte_Array;
      Ciphertext : Crypto.Byte_Array;
      Kind : Aead_Kind) return Crypto.Byte_Array;

end Crypto.Aead;
