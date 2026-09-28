pragma Ada_2022;

with Ada.Streams;
with Ada.Text_IO;
with Crypto;
with Crypto.Sign;

--  Public-key signatures: Ed25519.  A secret key signs; the public key
--  verifies.  Verify returns False (rather than raising) on a bad signature.
procedure Sign is

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

   declare
      Kp  : constant Crypto.Sign.Keypair := Crypto.Sign.Keygen;
      Msg : constant Crypto.Byte_Array := Bytes ("sign me");
      Sig : constant Crypto.Byte_Array := Crypto.Sign.Sign (Msg, Kp.Secret);
   begin
      Ada.Text_IO.Put_Line
        ("verify:    " & Boolean'Image (Crypto.Sign.Verify (Sig, Msg, Kp.Public)));
      Ada.Text_IO.Put_Line
        ("tampered:  "
         & Boolean'Image (Crypto.Sign.Verify (Sig, Bytes ("sign me!"), Kp.Public)));
      Ada.Text_IO.Put_Line
        ("signature: " & Crypto.Hex_Encode (Sig));
   end;
end Sign;
