pragma Ada_2022;

with Crypto.Sign;


--  Strongly-typed API over the Byte_Array-based binding: distinct value types
--  for keys, nonces, tags, signatures, seeds and keys of each shape, so the
--  compiler rejects supplying a Nonce where a Key (or any other) is expected.
--  Each is an ordinary copyable value type -- the point is compile-time type
--  distinction, not ownership or finalization -- so this stays a thin,
--  self-documenting convenience over the same C calls as the parent packages.
--  Convert to the raw binding with Bytes; from it with a type conversion
--  (e.g. Key (B)), which raises Constraint_Error on a wrong-length input.
package Crypto.Safe is

   type Key        is new Crypto.Byte_Array (1 .. Crypto.Key_Size);
   type Nonce      is new Crypto.Byte_Array (1 .. Crypto.Nonce_Size);
   type Auth_Tag   is new Crypto.Byte_Array (1 .. Crypto.Tag_Size);
   type Signature  is new Crypto.Byte_Array (1 .. Crypto.Sign.Signature_Size);
   type Public_Key is new Crypto.Byte_Array (1 .. Crypto.Sign.Public_Key_Size);
   type Secret_Key is new Crypto.Byte_Array (1 .. Crypto.Sign.Secret_Key_Size);
   type Seed       is new Crypto.Byte_Array (1 .. Crypto.Sign.Seed_Size);

   type Sealed_Text (Length : Natural) is record
      Ciphertext : Crypto.Byte_Array (1 .. Length);
      Tag        : Auth_Tag;
   end record;

   type Keypair is record
      Public : Public_Key;
      Secret : Secret_Key;
   end record;

   function Bytes (X : Key)        return Crypto.Byte_Array;
   function Bytes (X : Nonce)      return Crypto.Byte_Array;
   function Bytes (X : Auth_Tag)   return Crypto.Byte_Array;
   function Bytes (X : Signature)  return Crypto.Byte_Array;
   function Bytes (X : Public_Key) return Crypto.Byte_Array;
   function Bytes (X : Secret_Key) return Crypto.Byte_Array;
   function Bytes (X : Seed)       return Crypto.Byte_Array;

   function Random_Key return Key;
   function Random_Nonce return Nonce;

   --  ChaCha20-Poly1305, with a typed key/nonce and a typed tag in the result.
   function Seal (K : Key; N : Nonce; Aad, Plaintext : Crypto.Byte_Array)
      return Sealed_Text;
   function Open (K : Key; N : Nonce; Aad : Crypto.Byte_Array;
                  Text : Sealed_Text) return Crypto.Byte_Array;

   --  Ed25519, with typed keys and signature.
   function Keygen return Keypair;
   function Seed_Keypair (Sd : Seed) return Keypair;
   function Sign (Message : Crypto.Byte_Array; Sk : Secret_Key) return Signature;
   function Verify
     (Sig : Signature; Message : Crypto.Byte_Array; Pk : Public_Key)
      return Boolean;

end Crypto.Safe;
