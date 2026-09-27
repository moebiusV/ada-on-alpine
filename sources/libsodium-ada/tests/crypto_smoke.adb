pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Crypto;
with Crypto.Secretbox;
with Crypto.Sign;
use type Crypto.Byte_Array;

--  Packaging smoke test, run by the a port check() function: a handful of
--  round-trips and known vectors that must pass for the binding to be
--  considered working.  Exits non-zero on any failure.
procedure Crypto_Smoke is

   Failures : Natural := 0;

   procedure Check (Name : String; Ok : Boolean) is
   begin
      if Ok then
         Ada.Text_IO.Put_Line ("ok: " & Name);
      else
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
      end if;
   end Check;

   Empty : constant Crypto.Byte_Array (1 .. 0) := [others => 0];
begin
   Crypto.Init;

   --  ChaCha20-Poly1305 AEAD round-trip.
   declare
      Key   : constant Crypto.Byte_Array := [1 .. Crypto.Key_Size => 7];
      Nonce : constant Crypto.Byte_Array := [1 .. Crypto.Nonce_Size => 3];
      Msg   : constant Crypto.Byte_Array := [16#68#, 16#69#];
   begin
      Check
        ("seal/open round-trip",
         Crypto.Open
           (Key, Nonce, Empty, Crypto.Seal (Key, Nonce, Empty, Msg)) = Msg);
   end;

   --  Ed25519 round-trip.
   declare
      Kp  : constant Crypto.Sign.Keypair := Crypto.Sign.Keygen;
      Msg : constant Crypto.Byte_Array := [16#68#, 16#69#];
   begin
      Check
        ("sign/verify round-trip",
         Crypto.Sign.Verify
           (Crypto.Sign.Sign (Msg, Kp.Secret), Msg, Kp.Public));
   end;

   --  SHA-256 of the empty message (known vector).
   Check
     ("sha256 empty vector",
      Crypto.Hex_Encode (Crypto.Hash_Sha256 (Empty)) =
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");

   --  HMAC-SHA256, RFC 4231 test case 1.
   Check
     ("hmac rfc4231 tc1",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha256
           ([1 .. 20 => 16#0b#],
            [16#48#, 16#69#, 16#20#, 16#54#, 16#68#, 16#65#, 16#72#, 16#65#])) =
        "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7");

   --  Secretbox round-trip.
   declare
      Key   : constant Crypto.Byte_Array :=
        [1 .. Crypto.Secretbox.Key_Size => 9];
      Nonce : constant Crypto.Byte_Array :=
        [1 .. Crypto.Secretbox.Nonce_Size => 1];
      Msg   : constant Crypto.Byte_Array := [16#68#, 16#69#];
   begin
      Check
        ("secretbox round-trip",
         Crypto.Secretbox.Decrypt
           (Crypto.Secretbox.Encrypt (Msg, Nonce, Key), Nonce, Key) = Msg);
   end;

   --  Base64 round-trip.
   Check
     ("base64 round-trip",
      Crypto.Base64_Decode
        (Crypto.Base64_Encode
           (Crypto.Byte_Array'(16#de#, 16#ad#, 16#be#, 16#ef#))) =
        Crypto.Byte_Array'(16#de#, 16#ad#, 16#be#, 16#ef#));

   if Failures = 0 then
      Ada.Text_IO.Put_Line ("all crypto smoke checks passed");
   else
      Ada.Text_IO.Put_Line
        (Natural'Image (Failures) & " crypto smoke checks failed");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Crypto_Smoke;
