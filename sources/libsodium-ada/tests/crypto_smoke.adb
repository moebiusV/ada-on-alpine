pragma Ada_2022;

with Ada.Command_Line;
with Ada.Streams;
with Ada.Text_IO;
with Crypto;
with Crypto.Aead;
with Crypto.Auth;
with Crypto.Generichash;
with Crypto.Hash;
with Crypto.Kdf;
with Crypto.Pwhash;
with Crypto.Raw;
with Crypto.Safe;
with Crypto.Secretbox;
with Crypto.Secretstream;
with Crypto.Sign;
with Crypto.Stream;
use type Crypto.Byte_Array;
use type Crypto.Secretstream.Tag;

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

   --  Combined mode: Seal_Combined is Ciphertext || Tag; the RFC 8439 vector's
   --  combined form is its ciphertext and tag concatenated.
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
   begin
      Check
        ("aead combined rfc8439",
         Crypto.Hex_Encode (Crypto.Seal_Combined (Key, Nonce, Aad, Pt)) =
           "d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d6"
         & "3dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b36"
         & "92ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc"
         & "3ff4def08e4b7a9de576d26586cec64b6116"
         & "1ae10b594f09e26a7e902ecbd0600691");
      Check
        ("aead combined round-trip",
         Crypto.Open_Combined
           (Key, Nonce, Aad, Crypto.Seal_Combined (Key, Nonce, Aad, Pt)) = Pt);
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

   --  Streaming sign (ed25519ph) round-trip, exercising the state buffer at its
   --  exact crypto_sign_statebytes size (208, not the old oversized 512).
   declare
      Kp : constant Crypto.Sign.Keypair := Crypto.Sign.Keygen;
      St : Crypto.Sign.Sign_State := Crypto.Sign.New_State;
   begin
      Crypto.Sign.Update (St, B ("streaming "));
      Crypto.Sign.Update (St, B ("ed25519ph"));
      declare
         Sig : constant Crypto.Byte_Array :=
           Crypto.Sign.Final_Create (St, Kp.Secret);
         Vst : Crypto.Sign.Sign_State := Crypto.Sign.New_State;
      begin
         Crypto.Sign.Update (Vst, B ("streaming "));
         Crypto.Sign.Update (Vst, B ("ed25519ph"));
         Check
           ("sign streaming round-trip",
            Crypto.Sign.Final_Verify (Vst, Sig, Kp.Public));
      end;
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

   --  Streaming SHA-2 equals the one-shot hash, fed in uneven chunks and
   --  including a byte-at-a-time tail.
   declare
      Msg  : constant Crypto.Byte_Array := B ("The quick brown fox jumps over");
      St256 : Crypto.Hash.Sha256_State := Crypto.Hash.Sha256_Init;
      St512 : Crypto.Hash.Sha512_State := Crypto.Hash.Sha512_Init;
   begin
      Crypto.Hash.Sha256_Update (St256, B ("The quick brown fox "));
      Crypto.Hash.Sha256_Update (St256, B ("jumps "));
      Crypto.Hash.Sha256_Update (St256, B ("over"));
      Check
        ("sha256 streaming",
         Crypto.Hash.Sha256_Final (St256) = Crypto.Hash_Sha256 (Msg));

      Crypto.Hash.Sha512_Update (St512, B ("The quick "));
      Crypto.Hash.Sha512_Update (St512, B ("brown fox jumps"));
      Crypto.Hash.Sha512_Update (St512, B (" over"));
      Check
        ("sha512 streaming",
         Crypto.Hash.Sha512_Final (St512) = Crypto.Hash_Sha512 (Msg));
   end;

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

   --  Streaming HMAC (crypto_auth_hmacsha*_init/update/final) equals the
   --  one-shot HMAC for any key length; the SHA512-256 form matches crypto_auth.
   declare
      Msg  : constant Crypto.Byte_Array := B ("The quick brown fox");
      KeyA : constant Crypto.Byte_Array := B ("arbitrary length key");
      Key32 : constant Crypto.Byte_Array := [1 .. 32 => 5];
      S256 : Crypto.Auth.Hmac_Sha256_State := Crypto.Auth.Hmac_Sha256_Init (KeyA);
      S512 : Crypto.Auth.Hmac_Sha512_State := Crypto.Auth.Hmac_Sha512_Init (KeyA);
      S2   : Crypto.Auth.Hmac_Sha512_State :=
        Crypto.Auth.Hmac_Sha512_256_Init (Key32);
   begin
      Crypto.Auth.Hmac_Sha256_Update (S256, B ("The quick "));
      Crypto.Auth.Hmac_Sha256_Update (S256, B ("brown fox"));
      Crypto.Auth.Hmac_Sha512_Update (S512, B ("The quick "));
      Crypto.Auth.Hmac_Sha512_Update (S512, B ("brown fox"));
      Crypto.Auth.Hmac_Sha512_256_Update (S2, B ("The quick "));
      Crypto.Auth.Hmac_Sha512_256_Update (S2, B ("brown fox"));
      Check
        ("hmac-sha256 streaming",
         Crypto.Auth.Hmac_Sha256_Final (S256) = Crypto.Hmac_Sha256 (KeyA, Msg));
      Check
        ("hmac-sha512 streaming",
         Crypto.Auth.Hmac_Sha512_Final (S512) = Crypto.Hmac_Sha512 (KeyA, Msg));
      Check
        ("hmac-sha512256 streaming",
         Crypto.Auth.Hmac_Sha512_256_Final (S2) =
           Crypto.Auth.Authenticate (Msg, Key32));
   end;

   --  Stream keygen + keystream XOR is self-inverse (round-trips).
   declare
      Key   : constant Crypto.Byte_Array := Crypto.Stream.Keygen;
      Nonce : constant Crypto.Byte_Array := [1 .. 24 => 1];
      Msg   : constant Crypto.Byte_Array := B ("stream");
   begin
      Check
        ("stream keygen/encrypt round-trip",
         Crypto.Stream.Encrypt (Crypto.Stream.Encrypt (Msg, Nonce, Key), Nonce, Key)
           = Msg);
   end;

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
   --  Utils: constant-time compare, pad/unpad, alloc-array bounds
   ---------------------------------------------------------------

   --  Equal empty arrays are equal; this must not call memcmp(NULL,NULL,0).
   Check ("constant-time-equal empty",
          Crypto.Constant_Time_Equal (Empty, Empty));

   --  Unpad on an input whose 'First /= 1 (must slice relative to 'First).
   declare
      Msg   : constant Crypto.Byte_Array := B ("hello");
      Padded : constant Crypto.Byte_Array := Crypto.Pad (Msg, 16);
      Shift : Crypto.Byte_Array (5 .. 4 + Padded'Length);
   begin
      Shift := Padded;
      Check ("unpad slice-safe", Crypto.Unpad (Shift, 16) = Msg);
   end;

   --  Count * Size overflow is rejected before sodium_allocarray runs.
   declare
      Overflowed : Boolean := False;
   begin
      begin
         declare
            X : Crypto.Secure_Buffer :=
              Crypto.Secure_Alloc_Array (Natural'Last, 2);
         begin
            Crypto.Secure_Free (X);
         end;
      exception
         when Crypto.Crypto_Error =>
            Overflowed := True;
      end;
      Check ("secure_alloc_array overflow", Overflowed);
   end;

   --  Big-number helpers: Compare orders unsigned little-endian, Is_Zero is
   --  constant-time, and Sub is Add's inverse with wraparound.
   Check
     ("compare equal",
      Crypto.Compare (Crypto.Byte_Array'(16#01#, 16#02#),
                      Crypto.Byte_Array'(16#01#, 16#02#)) = 0);
   Check
     ("compare less",
      Crypto.Compare (Crypto.Byte_Array'(16#01#, 16#00#),
                      Crypto.Byte_Array'(16#02#, 16#00#)) = -1);
   Check
     ("compare greater",
      Crypto.Compare (Crypto.Byte_Array'(16#02#, 16#00#),
                      Crypto.Byte_Array'(16#01#, 16#00#)) = 1);
   Check ("is-zero all zero", Crypto.Is_Zero (Crypto.Byte_Array'(0, 0, 0)));
   Check ("is-zero nonzero", not Crypto.Is_Zero (Crypto.Byte_Array'(0, 1, 0)));
   Check ("is-zero empty", Crypto.Is_Zero (Empty));
   declare
      Buf : Crypto.Byte_Array := [16#05#, 16#00#];
   begin
      Crypto.Sub (Buf, Crypto.Byte_Array'(16#03#, 16#00#));
      Check ("sub little-endian", Buf = Crypto.Byte_Array'(16#02#, 16#00#));
   end;
   declare
      Buf : Crypto.Byte_Array := [0, 0];
   begin
      Crypto.Sub (Buf, Crypto.Byte_Array'(1, 0));
      Check ("sub wraparound", Buf = Crypto.Byte_Array'(16#ff#, 16#ff#));
   end;

   --  Generichash streaming equals the one-shot hash (and exercises the
   --  64-byte-aligned state path).
   declare
      Msg : constant Crypto.Byte_Array := B ("The quick brown fox");
      St  : Crypto.Generichash.Stream_State := Crypto.Generichash.New_State;
   begin
      Crypto.Generichash.Update (St, B ("The quick "));
      Crypto.Generichash.Update (St, B ("brown fox"));
      Check
        ("generichash streaming",
         Crypto.Generichash.Final (St) = Crypto.Generichash.Hash (Msg));
   end;

   ---------------------------------------------------------------
   --  KDF, secretstream rekey, scrypt rehash, AES-GCM probe
   ---------------------------------------------------------------

   --  KDF: deterministic, and distinct subkeys per id.
   declare
      Key : constant Crypto.Byte_Array := Crypto.Kdf.Keygen;
      Ctx : constant Crypto.Byte_Array := [1 .. Crypto.Kdf.Context_Size => 1];
      S1  : constant Crypto.Byte_Array :=
        Crypto.Kdf.Derive_From_Key (32, 1, Ctx, Key);
      S1b : constant Crypto.Byte_Array :=
        Crypto.Kdf.Derive_From_Key (32, 1, Ctx, Key);
      S2  : constant Crypto.Byte_Array :=
        Crypto.Kdf.Derive_From_Key (32, 2, Ctx, Key);
   begin
      Check ("kdf deterministic", S1 = S1b);
      Check ("kdf distinct subkey ids", S1 /= S2);
   end;

   --  Secretstream: round-trip with a manual key ratchet on both sides.
   declare
      Key : constant Crypto.Byte_Array := Crypto.Secretstream.Keygen;
      Pi  : constant Crypto.Secretstream.Push_Init :=
        Crypto.Secretstream.Init_Push (Key);
      St  : Crypto.Secretstream.Stream_State := Pi.State;
      C1  : constant Crypto.Byte_Array :=
        Crypto.Secretstream.Push
          (St, B ("one"), Empty, Crypto.Secretstream.Message);
   begin
      Crypto.Secretstream.Rekey (St);
      declare
         C2 : constant Crypto.Byte_Array :=
           Crypto.Secretstream.Push
             (St, B ("two"), Empty, Crypto.Secretstream.Message);
         C3 : constant Crypto.Byte_Array :=
           Crypto.Secretstream.Push
             (St, B ("three"), Empty, Crypto.Secretstream.Final);
         Pr : Crypto.Secretstream.Stream_State :=
           Crypto.Secretstream.Init_Pull (Pi.Header, Key);
      begin
         declare
            M1 : constant Crypto.Secretstream.Pulled :=
              Crypto.Secretstream.Pull (Pr, C1, Empty);
         begin
            Crypto.Secretstream.Rekey (Pr);
            declare
               M2 : constant Crypto.Secretstream.Pulled :=
                 Crypto.Secretstream.Pull (Pr, C2, Empty);
               M3 : constant Crypto.Secretstream.Pulled :=
                 Crypto.Secretstream.Pull (Pr, C3, Empty);
            begin
               Check
                 ("secretstream rekey round-trip",
                  M1.Message = B ("one") and M2.Message = B ("two")
                  and M3.Message = B ("three")
                  and M3.Kind = Crypto.Secretstream.Final);
            end;
         end;
      end;
   end;

   --  scrypt needs_rehash: a string hashed at the interactive preset wants
   --  rehashing at a higher ops cost, and not at its own cost.
   declare
      Pwd : constant Crypto.Byte_Array := B ("correct horse battery staple");
      S   : constant String :=
        Crypto.Pwhash.Scrypt_Str_Hash
          (Pwd,
           Crypto.Pwhash.Scrypt_Ops_Interactive,
           Crypto.Pwhash.Scrypt_Mem_Interactive);
   begin
      Check ("scrypt str verify", Crypto.Pwhash.Scrypt_Str_Verify (S, Pwd));
      Check
        ("scrypt str needs_rehash",
         Crypto.Pwhash.Scrypt_Str_Needs_Rehash
           (S,
            Crypto.Pwhash.Scrypt_Ops_Interactive * 2,
            Crypto.Pwhash.Scrypt_Mem_Interactive));
      Check
        ("scrypt str no rehash",
         not Crypto.Pwhash.Scrypt_Str_Needs_Rehash
           (S,
            Crypto.Pwhash.Scrypt_Ops_Interactive,
            Crypto.Pwhash.Scrypt_Mem_Interactive));
   end;

   --  AES-256-GCM: probe availability, and round-trip when it is available
   --  (it is on any AES-NI x86-64).
   if Crypto.Aead.Aes256gcm_Available then
      declare
         Key   : constant Crypto.Byte_Array := [1 .. 32 => 7];
         Nonce : constant Crypto.Byte_Array := [1 .. 12 => 3];
         Msg   : constant Crypto.Byte_Array := B ("aes");
         T     : constant Crypto.Aead.Sealed_Text :=
           Crypto.Aead.Seal (Msg, Nonce, Key, Empty, Crypto.Aead.Aes256gcm);
      begin
         Check
           ("aes256gcm round-trip",
            Crypto.Aead.Open (Key, Nonce, Empty, T, Crypto.Aead.Aes256gcm)
              = Msg);
      end;
   else
      Check ("aes256gcm unavailable (skipping round-trip)", True);
   end if;

   --  Combined AEAD across kinds: the ciphertext||tag buffer round-trips, and
   --  its length is Message'Length + Tag_Size.
   declare
      Key   : constant Crypto.Byte_Array := [1 .. 32 => 7];
      Nonce : constant Crypto.Byte_Array := [1 .. 12 => 3];
      Msg   : constant Crypto.Byte_Array := B ("combined aead");
      C     : constant Crypto.Byte_Array :=
        Crypto.Aead.Seal_Combined (Msg, Nonce, Key, Empty, Crypto.Aead.Chacha20_Ietf);
   begin
      Check ("aead combined length", C'Length = Msg'Length + Crypto.Tag_Size);
      Check
        ("aead combined round-trip",
         Crypto.Aead.Open_Combined
           (Key, Nonce, Empty, C, Crypto.Aead.Chacha20_Ietf) = Msg);
   end;

   --  AEGIS-128L/256: 32-byte tags, and Aegis128l takes a 16-byte key.
   declare
      Key   : constant Crypto.Byte_Array := [1 .. 16 => 7];
      Nonce : constant Crypto.Byte_Array := [1 .. 16 => 3];
      Msg   : constant Crypto.Byte_Array := B ("aegis128l");
      T     : constant Crypto.Aead.Sealed_Text :=
        Crypto.Aead.Seal (Msg, Nonce, Key, Empty, Crypto.Aead.Aegis128l);
   begin
      Check ("aegis128l tag size", T.Tag'Length = 32);
      Check
        ("aegis128l round-trip",
         Crypto.Aead.Open (Key, Nonce, Empty, T, Crypto.Aead.Aegis128l) = Msg);
      Check
        ("aegis128l combined round-trip",
         Crypto.Aead.Open_Combined
           (Key, Nonce, Empty,
            Crypto.Aead.Seal_Combined
              (Msg, Nonce, Key, Empty, Crypto.Aead.Aegis128l),
            Crypto.Aead.Aegis128l) = Msg);
   end;
   declare
      Key   : constant Crypto.Byte_Array := [1 .. 32 => 9];
      Nonce : constant Crypto.Byte_Array := [1 .. 32 => 4];
      Msg   : constant Crypto.Byte_Array := B ("aegis256");
      C     : constant Crypto.Byte_Array :=
        Crypto.Aead.Seal_Combined (Msg, Nonce, Key, Empty, Crypto.Aead.Aegis256);
   begin
      Check ("aegis256 combined length", C'Length = Msg'Length + 32);
      Check
        ("aegis256 combined round-trip",
         Crypto.Aead.Open_Combined (Key, Nonce, Empty, C, Crypto.Aead.Aegis256)
           = Msg);
   end;

   ---------------------------------------------------------------
   --  Raw state sizes match the linked libsodium ABI
   ---------------------------------------------------------------

   --  Each static statebytes constant must equal its runtime query, and the
   --  high-level packages must have derived their state sizes from them.
   Check
     ("raw sha256 statebytes",
      Natural (Crypto.Raw.Query_Hash_Sha256_Statebytes) =
        Crypto.Raw.Hash_Sha256_Statebytes);
   Check
     ("raw sha512 statebytes",
      Natural (Crypto.Raw.Query_Hash_Sha512_Statebytes) =
        Crypto.Raw.Hash_Sha512_Statebytes);
   Check
     ("raw generichash statebytes",
      Natural (Crypto.Raw.Query_Generichash_Statebytes) =
        Crypto.Raw.Generichash_Statebytes);
   Check
     ("raw sign statebytes",
      Natural (Crypto.Raw.Query_Sign_Statebytes) =
        Crypto.Raw.Sign_Statebytes);
   Check
     ("raw secretstream statebytes",
      Natural (Crypto.Raw.Query_Secretstream_Statebytes) =
        Crypto.Raw.Secretstream_Statebytes);
   Check
     ("raw auth-hmacsha256 statebytes",
      Natural (Crypto.Raw.Query_Auth_Hmac_Sha256_Statebytes) =
        Crypto.Raw.Auth_Hmac_Sha256_Statebytes);
   Check
     ("raw auth-hmacsha512 statebytes",
      Natural (Crypto.Raw.Query_Auth_Hmac_Sha512_Statebytes) =
        Crypto.Raw.Auth_Hmac_Sha512_Statebytes);
   Check
     ("raw auth-hmacsha512256 statebytes",
      Natural (Crypto.Raw.Query_Auth_Hmac_Sha512256_Statebytes) =
        Crypto.Raw.Auth_Hmac_Sha512256_Statebytes);

   ---------------------------------------------------------------
   --  Strongly-typed Safe layer
   ---------------------------------------------------------------

   declare
      K   : constant Crypto.Safe.Key := Crypto.Safe.Random_Key;
      N   : constant Crypto.Safe.Nonce := Crypto.Safe.Random_Nonce;
      Msg : constant Crypto.Byte_Array := B ("safe layer");
   begin
      Check
        ("safe seal/open round-trip",
         Crypto.Safe.Open (K, N, Empty, Crypto.Safe.Seal (K, N, Empty, Msg))
           = Msg);
   end;

   --  Safe.Seal is a faithful wrapper: the same key/nonce yields the same
   --  ciphertext and tag as the raw binding.
   declare
      Kb  : constant Crypto.Byte_Array := [1 .. 32 => 7];
      Nb  : constant Crypto.Byte_Array := [1 .. 12 => 3];
      K   : constant Crypto.Safe.Key := Crypto.Safe.Key (Kb);
      N   : constant Crypto.Safe.Nonce := Crypto.Safe.Nonce (Nb);
      Msg : constant Crypto.Byte_Array := B ("cross-check");
      Aad : constant Crypto.Byte_Array := B ("aad");
      S   : constant Crypto.Safe.Sealed_Text :=
        Crypto.Safe.Seal (K, N, Aad, Msg);
      R   : constant Crypto.Sealed_Text := Crypto.Seal (Kb, Nb, Aad, Msg);
   begin
      Check
        ("safe seal matches raw",
         S.Ciphertext = R.Ciphertext and Crypto.Safe.Bytes (S.Tag) = R.Tag);
   end;

   --  Ed25519 with typed keys and signature.
   declare
      Kp  : constant Crypto.Safe.Keypair := Crypto.Safe.Keygen;
      Msg : constant Crypto.Byte_Array := B ("typed sign");
   begin
      Check
        ("safe sign/verify round-trip",
         Crypto.Safe.Verify
           (Crypto.Safe.Sign (Msg, Kp.Secret), Msg, Kp.Public));
   end;

   --  Deterministic seed keypair matches the raw binding's (RFC 8032 seed).
   declare
      Sd  : constant Crypto.Safe.Seed :=
        Crypto.Safe.Seed
          (Crypto.Hex_Decode
             ("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"));
      Kp1 : constant Crypto.Safe.Keypair := Crypto.Safe.Seed_Keypair (Sd);
      Kp2 : constant Crypto.Safe.Keypair := Crypto.Safe.Seed_Keypair (Sd);
      Raw : constant Crypto.Sign.Keypair :=
        Crypto.Sign.Seed_Keypair
          (Crypto.Hex_Decode
             ("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"));
   begin
      Check
        ("safe seed keypair deterministic",
         Crypto.Safe.Bytes (Kp1.Public) = Crypto.Safe.Bytes (Kp2.Public));
      Check
        ("safe seed keypair matches raw",
         Crypto.Safe.Bytes (Kp1.Public) = Raw.Public);
   end;

   --  Random key/nonce have the fixed widths, and Bytes round-trips.
   declare
      K : constant Crypto.Safe.Key := Crypto.Safe.Random_Key;
      N : constant Crypto.Safe.Nonce := Crypto.Safe.Random_Nonce;
   begin
      Check
        ("safe random widths",
         Crypto.Safe.Bytes (K)'Length = 32
         and Crypto.Safe.Bytes (N)'Length = 12);
      Check
        ("safe bytes round-trip",
         Crypto.Safe.Bytes (Crypto.Safe.Key (Crypto.Safe.Bytes (K)))
           = Crypto.Safe.Bytes (K));
   end;

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
