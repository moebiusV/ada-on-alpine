pragma Ada_2022;


--  Public-key authenticated encryption (crypto_box_*, Curve25519-XSalsa20-
--  Poly1305): sender/recipient keypairs, combined and detached modes, a
--  precomputed shared key for repeated use, and anonymous sealed boxes.
package Crypto.Box is

   Public_Key_Size       : constant := 32;
   Secret_Key_Size       : constant := 32;
   Seed_Size             : constant := 32;
   Nonce_Size            : constant := 24;
   Mac_Size              : constant := 16;
   Before_Shared_Key_Size : constant := 32;
   Seal_Size             : constant := 48;  --  pubkey + mac, added to message

   type Keypair is record
      Public : Crypto.Byte_Array (1 .. Public_Key_Size);
      Secret : Crypto.Byte_Array (1 .. Secret_Key_Size);
   end record;

   type Variant is (Xsalsa20, Xchacha20);

   type Detached_Text (Length : Natural) is record
      Ciphertext : Crypto.Byte_Array (1 .. Length);
      Mac        : Crypto.Byte_Array (1 .. Mac_Size);
   end record;

   function Keygen return Keypair;
   function Seed_Keypair (Seed : Crypto.Byte_Array) return Keypair;

   --  Combined encryption/decryption.  Decrypt raises Crypto_Error on a bad
   --  ciphertext or nonce.
   function Encrypt
     (Message    : Crypto.Byte_Array;
      Nonce      : Crypto.Byte_Array;
      Public_Key : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array;
      V          : Variant := Xsalsa20) return Crypto.Byte_Array;
   function Decrypt
     (Ciphertext : Crypto.Byte_Array;
      Nonce      : Crypto.Byte_Array;
      Public_Key : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array;
      V          : Variant := Xsalsa20) return Crypto.Byte_Array;

   --  Detached encryption/decryption (ciphertext and MAC kept separate).
   function Encrypt_Detached
     (Message    : Crypto.Byte_Array;
      Nonce      : Crypto.Byte_Array;
      Public_Key : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array;
      V          : Variant := Xsalsa20) return Detached_Text;
   function Decrypt_Detached
     (Text       : Detached_Text;
      Nonce      : Crypto.Byte_Array;
      Public_Key : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array;
      V          : Variant := Xsalsa20) return Crypto.Byte_Array;

   --  Precompute the shared key, then use the *After_Shared forms to skip the
   --  scalar multiplication on each message.
   function Before_Shared
     (Public_Key, Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Encrypt_After_Shared
     (Message, Nonce, Shared_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Decrypt_After_Shared
     (Ciphertext, Nonce, Shared_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array;

   --  Anonymous sealed box (only the recipient's keys are used).
   function Seal
     (Message, Public_Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Seal_Open
     (Ciphertext : Crypto.Byte_Array;
      Public_Key : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array;

end Crypto.Box;
