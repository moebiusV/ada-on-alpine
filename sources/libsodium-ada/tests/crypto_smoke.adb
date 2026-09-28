pragma Ada_2022;

with Ada.Command_Line;
with Ada.Streams;
with Ada.Text_IO;
with Crypto;
with Crypto.Secretbox;
with Crypto.Sign;
use type Crypto.Byte_Array;

--  Packaging smoke test, run by the a port check() function: round-trips and
--  known-answer vectors (RFC 4231 HMAC, NIST SHA-256/512, RFC 8439 AEAD,
--  RFC 8032 Ed25519, RFC 4648 base64) that must pass for the binding to be
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

   --  ASCII string to bytes (for RFC vector inputs presented as text).
   function B (S : String) return Crypto.Byte_Array is
      Result : Crypto.Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         Result (I - S'First + 1) :=
           Ada.Streams.Stream_Element (Character'Pos (S (I)));
      end loop;
      return Result;
   end B;

   Empty : constant Crypto.Byte_Array (1 .. 0) := [others => 0];
begin
   Crypto.Init;

   ---------------------------------------------------------------
   --  ChaCha20-Poly1305 AEAD
   ---------------------------------------------------------------

   --  Round-trip.
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

   --  RFC 8439 section 2.8.2 known-answer: full key/nonce/AAD/plaintext to
   --  the expected ciphertext and tag.
   declare
      Key   : constant Crypto.Byte_Array :=
        Crypto.Hex_Decode
          ("808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f");
      Nonce : constant Crypto.Byte_Array :=
        Crypto.Hex_Decode ("070000004041424344454647");
      Aad   : constant Crypto.Byte_Array :=
        Crypto.Hex_Decode ("50515253c0c1c2c3c4c5c6c7");
      Pt    : constant Crypto.Byte_Array :=
        B ("Ladies and Gentlemen of the class of '99: If I could offer you "
         & "only one tip for the future, sunscreen would be it.");
      Sealed : constant Crypto.Sealed_Text := Crypto.Seal (Key, Nonce, Aad, Pt);
   begin
      Check
        ("aead rfc8439 ciphertext",
         Crypto.Hex_Encode (Sealed.Ciphertext) =
           "d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d6"
         & "3dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b36"
         & "92ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc"
         & "3ff4def08e4b7a9de576d26586cec64b6116");
      Check
        ("aead rfc8439 tag",
         Crypto.Hex_Encode (Sealed.Tag) =
           "1ae10b594f09e26a7e902ecbd0600691");
      Check
        ("aead rfc8439 open",
         Crypto.Open (Key, Nonce, Aad, Sealed) = Pt);
   end;

   ---------------------------------------------------------------
   --  Ed25519 signatures
   ---------------------------------------------------------------

   --  Round-trip.
   declare
      Kp  : constant Crypto.Sign.Keypair := Crypto.Sign.Keygen;
      Msg : constant Crypto.Byte_Array := [16#68#, 16#69#];
   begin
      Check
        ("sign/verify round-trip",
         Crypto.Sign.Verify
           (Crypto.Sign.Sign (Msg, Kp.Secret), Msg, Kp.Public));
   end;

   --  RFC 8032 section 7.1 test 1: deterministic keypair from the seed, its
   --  public key, and the signature of the empty message, byte for byte.
   declare
      Kp  : constant Crypto.Sign.Keypair :=
        Crypto.Sign.Seed_Keypair
          (Crypto.Hex_Decode
             ("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"));
      Sig : constant Crypto.Byte_Array := Crypto.Sign.Sign (Empty, Kp.Secret);
   begin
      Check
        ("ed25519 rfc8032 public key",
         Crypto.Hex_Encode (Kp.Public) =
           "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a");
      Check
        ("ed25519 rfc8032 signature",
         Crypto.Hex_Encode (Sig) =
           "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e06522490155"
         & "5fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b");
      Check ("ed25519 rfc8032 verify", Crypto.Sign.Verify (Sig, Empty, Kp.Public));
   end;

   ---------------------------------------------------------------
   --  SHA-256 / SHA-512 (NIST known-answer tests)
   ---------------------------------------------------------------

   Check
     ("sha256 empty vector",
      Crypto.Hex_Encode (Crypto.Hash_Sha256 (Empty)) =
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");

   Check
     ("sha256 abc",
      Crypto.Hex_Encode (Crypto.Hash_Sha256 (B ("abc"))) =
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");

   Check
     ("sha256 two-block",
      Crypto.Hex_Encode
        (Crypto.Hash_Sha256
           (B ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"))) =
        "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");

   Check
     ("sha512 empty vector",
      Crypto.Hex_Encode (Crypto.Hash_Sha512 (Empty)) =
        "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce"
      & "47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e");

   Check
     ("sha512 abc",
      Crypto.Hex_Encode (Crypto.Hash_Sha512 (B ("abc"))) =
        "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a"
      & "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f");

   ---------------------------------------------------------------
   --  HMAC (RFC 4231 test cases)
   ---------------------------------------------------------------

   Check
     ("hmac-sha256 rfc4231 tc1",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha256
           ([1 .. 20 => 16#0b#],
            [16#48#, 16#69#, 16#20#, 16#54#, 16#68#, 16#65#, 16#72#, 16#65#])) =
        "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7");

   Check
     ("hmac-sha256 rfc4231 tc2",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha256
           (B ("Jefe"), B ("what do ya want for nothing?"))) =
        "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843");

   Check
     ("hmac-sha256 rfc4231 tc3",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha256 ([1 .. 20 => 16#aa#], [1 .. 50 => 16#dd#])) =
        "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe");

   Check
     ("hmac-sha256 rfc4231 tc4",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha256
           (Crypto.Hex_Decode
              ("0102030405060708090a0b0c0d0e0f10111213141516171819"),
            [1 .. 50 => 16#cd#])) =
        "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b");

   Check
     ("hmac-sha256 rfc4231 tc6",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha256
           ([1 .. 131 => 16#aa#],
            B ("Test Using Larger Than Block-Size Key - Hash Key First"))) =
        "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54");

   Check
     ("hmac-sha256 rfc4231 tc7",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha256
           ([1 .. 131 => 16#aa#],
            B ("This is a test using a larger than block-size key and a larger"
             & " than block-size data. The key needs to be hashed before being"
             & " used by the HMAC algorithm."))) =
        "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2");

   Check
     ("hmac-sha512 rfc4231 tc1",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha512
           ([1 .. 20 => 16#0b#],
            [16#48#, 16#69#, 16#20#, 16#54#, 16#68#, 16#65#, 16#72#, 16#65#])) =
        "87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cde"
      & "daa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854");

   Check
     ("hmac-sha512 rfc4231 tc2",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha512
           (B ("Jefe"), B ("what do ya want for nothing?"))) =
        "164b7a7bfcf819e2e395fbe73b56e0a387bd64222e831fd610270cd7ea250554"
      & "9758bf75c05a994a6d034f65f8f0e6fdcaeab1a34d4a6b4b636e070a38bce737");

   Check
     ("hmac-sha512 rfc4231 tc6",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha512
           ([1 .. 131 => 16#aa#],
            B ("Test Using Larger Than Block-Size Key - Hash Key First"))) =
        "80b24263c7c1a3ebb71493c1dd7be8b49b46d1f41b4aeec1121b013783f8f352"
      & "6b56d037e05f2598bd0fd2215d6a1e5295e64f73f63f0aec8b915a985d786598");

   Check
     ("hmac-sha512 rfc4231 tc7",
      Crypto.Hex_Encode
        (Crypto.Hmac_Sha512
           ([1 .. 131 => 16#aa#],
            B ("This is a test using a larger than block-size key and a larger"
             & " than block-size data. The key needs to be hashed before being"
             & " used by the HMAC algorithm."))) =
        "e37b6a775dc87dbaa4dfa9f96e5e3ffddebd71f8867289865df5a32d20cdc944"
      & "b6022cac3c4982b10d5eeb55c3e4de15134676fb6de0446065c97440fa8c6a58");

   ---------------------------------------------------------------
   --  Secretbox
   ---------------------------------------------------------------

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

   ---------------------------------------------------------------
   --  Base64 / Hex (RFC 4648 known vectors)
   ---------------------------------------------------------------

   Check
     ("base64 rfc4648 f",
      Crypto.Base64_Encode (B ("f")) = "Zg==");

   Check
     ("base64 rfc4648 fo",
      Crypto.Base64_Encode (B ("fo")) = "Zm8=");

   Check
     ("base64 rfc4648 foobar",
      Crypto.Base64_Encode (B ("foobar")) = "Zm9vYmFy");

   Check
     ("base64 decode round-trip",
      Crypto.Base64_Decode
        (Crypto.Base64_Encode
           (Crypto.Byte_Array'(16#de#, 16#ad#, 16#be#, 16#ef#))) =
        Crypto.Byte_Array'(16#de#, 16#ad#, 16#be#, 16#ef#));

   Check
     ("hex encode",
      Crypto.Hex_Encode (B ("foobar")) = "666f6f626172");

   Check
     ("hex decode round-trip",
      Crypto.Hex_Decode ("666f6f626172") = B ("foobar"));

   ---------------------------------------------------------------
   --  Guarded storage
   ---------------------------------------------------------------

   --  Wipe / Secure_Free must not fault on a buffer that has been Protect'd
   --  read-only or no-access (Wipe restores write access first; a raw write
   --  into a read-only page would SIGSEGV).  Reaching the Check line is itself
   --  the assertion: a fault or propagated exception would abort the process.
   declare
      Buf : Crypto.Secure_Buffer := Crypto.Secure_Alloc (16);
   begin
      Crypto.Fill (Buf, [1 .. 16 => 16#2a#]);
      Crypto.Protect (Buf, Crypto.Read_Only);
      Crypto.Wipe (Buf);
      Crypto.Protect (Buf, Crypto.No_Access);
      Crypto.Secure_Free (Buf);
      Check ("wipe protected guarded buffer", True);
   end;

   if Failures = 0 then
      Ada.Text_IO.Put_Line ("all crypto smoke checks passed");
   else
      Ada.Text_IO.Put_Line
        (Natural'Image (Failures) & " crypto smoke checks failed");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Crypto_Smoke;
