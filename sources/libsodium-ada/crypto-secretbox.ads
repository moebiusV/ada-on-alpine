pragma Ada_2022;


--  Symmetric authenticated encryption (crypto_secretbox_*, XSalsa20-
--  Poly1305): a single shared key, combined or detached mode.
package Crypto.Secretbox is

   Key_Size   : constant := 32;
   Nonce_Size : constant := 24;
   Mac_Size   : constant := 16;

   type Detached_Text (Length : Natural) is record
      Ciphertext : Crypto.Byte_Array (1 .. Length);
      Mac        : Crypto.Byte_Array (1 .. Mac_Size);
   end record;

   function Encrypt
     (Message, Nonce, Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Decrypt
     (Ciphertext, Nonce, Key : Crypto.Byte_Array) return Crypto.Byte_Array;

   function Encrypt_Detached
     (Message, Nonce, Key : Crypto.Byte_Array) return Detached_Text;
   function Decrypt_Detached
     (Text : Detached_Text; Nonce, Key : Crypto.Byte_Array)
      return Crypto.Byte_Array;

end Crypto.Secretbox;
