pragma Ada_2022;


--  Authenticated encryption with associated data (crypto_aead_*), across the
--  primitives libsodium ships.  Each Kind has its own key, nonce and tag
--  (abytes) length; the Sealed_Text result carries the tag at its actual
--  length rather than a fixed Crypto.Tag_Size.
package Crypto.Aead is

   type Aead_Kind is
     (Chacha20_Ietf, Xchacha20_Ietf, Chacha20, Aes256gcm,
      Aegis128l, Aegis256);

   function Key_Size (Kind : Aead_Kind) return Natural is
     (case Kind is
        when Aegis128l => 16,
        when others    => 32);
   function Nonce_Size (Kind : Aead_Kind) return Natural is
     (case Kind is
        when Xchacha20_Ietf => 24,
        when Chacha20       => 8,
        when Aegis128l      => 16,
        when Aegis256       => 32,
        when others         => 12);
   --  Tag length (crypto_aead_*_ABYTES): 16 for the Poly1305 primitives, 32
   --  for AEGIS.
   function Abytes (Kind : Aead_Kind) return Natural is
     (case Kind is
        when Aegis128l | Aegis256 => 32,
        when others               => 16);

   --  AES-256-GCM needs the AES-NI instructions; on a CPU without them this
   --  is False and Seal/Open with Aes256gcm will fail.  Probe before use.
   --  AEGIS is a software primitive and always available.
   function Aes256gcm_Available return Boolean;

   --  Ciphertext and tag, the tag at the primitive's actual length.
   type Sealed_Text (Length, Tag_Length : Natural) is record
      Ciphertext : Crypto.Byte_Array (1 .. Length);
      Tag        : Crypto.Byte_Array (1 .. Tag_Length);
   end record;

   function Seal
     (Message : Crypto.Byte_Array;
      Nonce, Key, Aad : Crypto.Byte_Array;
      Kind : Aead_Kind) return Sealed_Text;
   function Open
     (Key, Nonce, Aad : Crypto.Byte_Array;
      Text : Sealed_Text;
      Kind : Aead_Kind) return Crypto.Byte_Array;

   --  Combined-mode (crypto_aead_*_encrypt/decrypt): the ciphertext and tag
   --  concatenated into one buffer, Ciphertext || Tag.  Seal_Combined returns
   --  Message'Length + Abytes (Kind) bytes; Open_Combined recovers the
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
