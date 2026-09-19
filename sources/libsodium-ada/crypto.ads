pragma Ada_2022;

with Ada.Streams;

--  Thin binding over libsodium (plan Section 2): cryptographically random
--  bytes, HMAC-SHA256, and ChaCha20-Poly1305 AEAD.  This package owns the C
--  object lifetimes and turns C error returns into Ada results; no raw
--  pointers escape above it.

package Crypto is

   type Byte_Array is array (Natural range <>) of Ada.Streams.Stream_Element;

   Key_Size   : constant := 32;   --  ChaCha20 key
   Nonce_Size : constant := 12;   --  ChaCha20-Poly1305 nonce
   Tag_Size   : constant := 16;   --  Poly1305 authentication tag
   Hmac_Size  : constant := 32;   --  SHA-256 digest

   type Sealed_Text (Length : Natural) is record
      Ciphertext : Byte_Array (1 .. Length);
      Tag        : Byte_Array (1 .. Tag_Size);
   end record;

   Crypto_Error : exception;

   --  Cryptographically random bytes.
   function Random (N : Natural) return Byte_Array;

   --  HMAC-SHA256, as used for KuCoin request signing.
   function Hmac_Sha256
     (Key  : Byte_Array;
      Data : Byte_Array) return Byte_Array;

   --  ChaCha20-Poly1305 seal.  Key and Nonce must be Key_Size and Nonce_Size
   --  bytes; Aad may be empty.  Ciphertext has the plaintext length.
   function Seal
     (Key, Nonce, Aad, Plaintext : Byte_Array) return Sealed_Text;

   --  ChaCha20-Poly1305 open; raises Crypto_Error on authentication failure.
   function Open
     (Key, Nonce, Aad : Byte_Array;
      Text            : Sealed_Text) return Byte_Array;

end Crypto;
