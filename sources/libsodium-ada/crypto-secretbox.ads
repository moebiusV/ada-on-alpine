pragma Ada_2022;


--  Symmetric authenticated encryption (crypto_secretbox_*): a single shared
--  key, combined or detached mode, over XSalsa20-Poly1305 or
--  XChaCha20-Poly1305 (selected by Variant; the key, nonce and MAC sizes are
--  the same for both).
package Crypto.Secretbox is

   Key_Size   : constant := 32;
   Nonce_Size : constant := 24;
   Mac_Size   : constant := 16;

   type Variant is (Xsalsa20, Xchacha20);

   type Detached_Text (Length : Natural) is record
      Ciphertext : Crypto.Byte_Array (1 .. Length);
      Mac        : Crypto.Byte_Array (1 .. Mac_Size);
   end record;

   function Encrypt
     (Message, Nonce, Key : Crypto.Byte_Array;
      V : Variant := Xsalsa20) return Crypto.Byte_Array;
   function Decrypt
     (Ciphertext, Nonce, Key : Crypto.Byte_Array;
      V : Variant := Xsalsa20) return Crypto.Byte_Array;

   function Encrypt_Detached
     (Message, Nonce, Key : Crypto.Byte_Array;
      V : Variant := Xsalsa20) return Detached_Text;
   function Decrypt_Detached
     (Text : Detached_Text; Nonce, Key : Crypto.Byte_Array;
      V : Variant := Xsalsa20) return Crypto.Byte_Array;

end Crypto.Secretbox;
