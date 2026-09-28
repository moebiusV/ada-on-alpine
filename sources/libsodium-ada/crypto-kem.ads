pragma Ada_2022;


--  Key encapsulation mechanisms (crypto_kem_*, ML-KEM-768 and X-Wing):
--  post-quantum key establishment.  Keygen produces a keypair; Encapsulate
--  derives a shared secret and the ciphertext that conveys it to the peer;
--  Decapsulate recovers the shared secret from the ciphertext and secret key.
package Crypto.Kem is

   type Algorithm is (Mlkem768, Xwing);

   Shared_Secret_Size : constant := 32;

   function Public_Key_Size (A : Algorithm) return Natural is
     (case A is when Mlkem768 => 1184, when Xwing => 1216);
   function Secret_Key_Size (A : Algorithm) return Natural is
     (case A is when Mlkem768 => 2400, when Xwing => 32);
   function Ciphertext_Size (A : Algorithm) return Natural is
     (case A is when Mlkem768 => 1088, when Xwing => 1120);
   function Seed_Size (A : Algorithm) return Natural is
     (case A is when Mlkem768 => 64, when Xwing => 32);

   --  Component arrays are sized by the discriminants, which the constructors
   --  set from the Algorithm (Public_Key_Size etc.).
   type Keypair (Public_Size, Secret_Size : Natural) is record
      Public : Crypto.Byte_Array (1 .. Public_Size);
      Secret : Crypto.Byte_Array (1 .. Secret_Size);
   end record;

   --  The ciphertext to hand the peer, and the shared secret both sides end
   --  up with.
   type Sealed (Ct_Size : Natural) is record
      Ciphertext : Crypto.Byte_Array (1 .. Ct_Size);
      Shared     : Crypto.Byte_Array (1 .. Shared_Secret_Size);
   end record;

   function Keygen (A : Algorithm) return Keypair;

   --  Deterministic keypair from a Seed_Size-byte seed.
   function Seed_Keypair (Seed : Crypto.Byte_Array; A : Algorithm)
      return Keypair;

   function Encapsulate (Public_Key : Crypto.Byte_Array; A : Algorithm)
      return Sealed;

   function Decapsulate
     (Ciphertext, Secret_Key : Crypto.Byte_Array; A : Algorithm)
      return Crypto.Byte_Array;

end Crypto.Kem;
