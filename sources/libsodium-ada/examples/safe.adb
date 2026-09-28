pragma Ada_2022;

with Ada.Streams;
with Ada.Text_IO;
with Crypto;
with Crypto.Safe;

--  The strongly-typed layer (Crypto.Safe): Key, Nonce, Auth_Tag, Signature and
--  the Ed25519 keypair types are distinct, so the compiler rejects passing a
--  Nonce where a Key is expected.  Convert to the raw binding with Bytes, and
--  from it with a type conversion (e.g. Key (B)).
procedure Safe is

   use type Crypto.Byte_Array;

   function Bytes (S : String) return Crypto.Byte_Array is
      R : Crypto.Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) :=
           Ada.Streams.Stream_Element (Character'Pos (S (I)));
      end loop;
      return R;
   end Bytes;

begin
   Crypto.Init;

   --  Secret-key encryption with typed Key/Nonce and a typed tag in the result.
   declare
      K      : constant Crypto.Safe.Key := Crypto.Safe.Random_Key;
      N      : constant Crypto.Safe.Nonce := Crypto.Safe.Random_Nonce;
      Msg    : constant Crypto.Byte_Array := Bytes ("typed secret");
      Sealed : constant Crypto.Safe.Sealed_Text :=
        Crypto.Safe.Seal (K, N, Bytes (""), Msg);
   begin
      Ada.Text_IO.Put_Line
        ("safe seal/open: "
         & Boolean'Image (Crypto.Safe.Open (K, N, Bytes (""), Sealed) = Msg));
   end;

   --  Typed Ed25519 keys and signature.
   declare
      Kp  : constant Crypto.Safe.Keypair := Crypto.Safe.Keygen;
      Msg : constant Crypto.Byte_Array := Bytes ("typed sign");
      Sig : constant Crypto.Safe.Signature := Crypto.Safe.Sign (Msg, Kp.Secret);
   begin
      Ada.Text_IO.Put_Line
        ("safe verify:    "
         & Boolean'Image (Crypto.Safe.Verify (Sig, Msg, Kp.Public)));
   end;
end Safe;
