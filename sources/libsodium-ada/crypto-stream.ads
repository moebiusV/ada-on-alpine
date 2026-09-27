pragma Ada_2022;


--  Stream ciphers (crypto_stream_*): generate a keystream or XOR a message
--  with one, under a 32-byte key and a kind-specific nonce length.
package Crypto.Stream is

   Key_Size : constant := 32;

   type Stream_Kind is
     (XSalsa20, XChacha20, ChaCha20, ChaCha20_Ietf,
      Salsa20, Salsa2012, Salsa208);

   function Nonce_Size (Kind : Stream_Kind) return Natural;

   --  Length bytes of keystream (for the given nonce/key), or the message
   --  XORed with the keystream (Encrypt is self-inverse, so the same call
   --  decrypts).
   function Keystream
     (Length : Natural;
      Nonce, Key : Crypto.Byte_Array;
      Kind : Stream_Kind := XSalsa20) return Crypto.Byte_Array;
   function Encrypt
     (Message : Crypto.Byte_Array;
      Nonce, Key : Crypto.Byte_Array;
      Kind : Stream_Kind := XSalsa20) return Crypto.Byte_Array;

end Crypto.Stream;
