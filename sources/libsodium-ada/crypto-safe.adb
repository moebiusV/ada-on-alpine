pragma Ada_2022;

package body Crypto.Safe is

   function Bytes (X : Key)        return Crypto.Byte_Array is
     (Crypto.Byte_Array (X));
   function Bytes (X : Nonce)      return Crypto.Byte_Array is
     (Crypto.Byte_Array (X));
   function Bytes (X : Auth_Tag)   return Crypto.Byte_Array is
     (Crypto.Byte_Array (X));
   function Bytes (X : Signature)  return Crypto.Byte_Array is
     (Crypto.Byte_Array (X));
   function Bytes (X : Public_Key) return Crypto.Byte_Array is
     (Crypto.Byte_Array (X));
   function Bytes (X : Secret_Key) return Crypto.Byte_Array is
     (Crypto.Byte_Array (X));
   function Bytes (X : Seed)       return Crypto.Byte_Array is
     (Crypto.Byte_Array (X));

   function Random_Key return Key is
      B : constant Crypto.Byte_Array := Crypto.Random (Crypto.Key_Size);
   begin
      return Key (B);
   end Random_Key;

   function Random_Nonce return Nonce is
      B : constant Crypto.Byte_Array := Crypto.Random (Crypto.Nonce_Size);
   begin
      return Nonce (B);
   end Random_Nonce;

   function Seal (K : Key; N : Nonce; Aad, Plaintext : Crypto.Byte_Array)
      return Sealed_Text
   is
      S : constant Crypto.Sealed_Text :=
        Crypto.Seal (Bytes (K), Bytes (N), Aad, Plaintext);
   begin
      return Sealed_Text'
        (Length     => S.Ciphertext'Length,
         Ciphertext => S.Ciphertext,
         Tag        => Auth_Tag (S.Tag));
   end Seal;

   function Open (K : Key; N : Nonce; Aad : Crypto.Byte_Array;
                  Text : Sealed_Text) return Crypto.Byte_Array
   is
      S : constant Crypto.Sealed_Text :=
        Crypto.Sealed_Text'
          (Length     => Text.Ciphertext'Length,
           Ciphertext => Text.Ciphertext,
           Tag        => Bytes (Text.Tag));
   begin
      return Crypto.Open (Bytes (K), Bytes (N), Aad, S);
   end Open;

   function Keygen return Keypair is
      Kp : constant Crypto.Sign.Keypair := Crypto.Sign.Keygen;
   begin
      return (Public => Public_Key (Kp.Public),
              Secret => Secret_Key (Kp.Secret));
   end Keygen;

   function Seed_Keypair (Sd : Seed) return Keypair is
      Kp : constant Crypto.Sign.Keypair :=
        Crypto.Sign.Seed_Keypair (Bytes (Sd));
   begin
      return (Public => Public_Key (Kp.Public),
              Secret => Secret_Key (Kp.Secret));
   end Seed_Keypair;

   function Sign (Message : Crypto.Byte_Array; Sk : Secret_Key)
      return Signature
   is
      S : constant Crypto.Byte_Array :=
        Crypto.Sign.Sign (Message, Bytes (Sk));
   begin
      return Signature (S);
   end Sign;

   function Verify
     (Sig : Signature; Message : Crypto.Byte_Array; Pk : Public_Key)
      return Boolean
   is
   begin
      return Crypto.Sign.Verify (Bytes (Sig), Message, Bytes (Pk));
   end Verify;

end Crypto.Safe;
