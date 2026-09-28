pragma Ada_2022;

with Ada.Streams;
with Interfaces;
with System;

--  Thin, complete binding over libsodium.  Core package: library init and
--  version, random bytes, hashes and keyed hashes, base-64 and hex encoding,
--  constant-time comparison, little-endian big-number helpers, guarded secret
--  storage, and ChaCha20-Poly1305 AEAD.  The higher-level primitives (box,
--  sign, secretbox, secretstream, generichash, pwhash, stream, scalarmult,
--  kx, shorthash, auth) live in child packages (Crypto.Box, Crypto.Sign,
--  ...).  This package owns the C object lifetimes and turns C error returns
--  into Ada results; no raw pointers escape above it.

package Crypto is

   type Byte_Array is array (Natural range <>) of Ada.Streams.Stream_Element;

   --  Sizes (bytes) of the fixed-length primitives.
   Key_Size     : constant := 32;   --  ChaCha20-Poly1305 key
   Nonce_Size   : constant := 12;   --  ChaCha20-Poly1305 (IETF) nonce
   Tag_Size     : constant := 16;   --  Poly1305 authentication tag
   Hmac_Size    : constant := 32;   --  SHA-256 digest
   Hash256_Size : constant := 32;   --  SHA-256 digest
   Hash512_Size : constant := 64;   --  SHA-512 digest
   Seed_Size    : constant := 32;   --  randombytes_buf_deterministic seed

   type Sealed_Text (Length : Natural) is record
      Ciphertext : Byte_Array (1 .. Length);
      Tag        : Byte_Array (1 .. Tag_Size);
   end record;

   Crypto_Error : exception;

   --  Library initialisation and version.  Init is safe to call more than
   --  once; it raises Crypto_Error only on a hard failure.
   procedure Init;
   function Version_String return String;
   function Version_Major return Natural;
   function Version_Minor return Natural;

   --  Random bytes, a bounded uniform draw, and a seeded deterministic stream
   --  (for reproducible tests).  Seed must be Seed_Size bytes.
   function Random (N : Natural) return Byte_Array;
   function Random_Uniform (Upper_Bound : Interfaces.Unsigned_32)
      return Interfaces.Unsigned_32;
   function Random_Deterministic (N : Natural; Seed : Byte_Array)
      return Byte_Array;

   --  One-shot hashes and keyed hashes (RFC 2104 HMAC composed over the raw
   --  SHA-256/SHA-512 hash so keys of any length work).
   function Hash_Sha256 (Data : Byte_Array) return Byte_Array;
   function Hash_Sha512 (Data : Byte_Array) return Byte_Array;
   function Hash_Sha3_256 (Data : Byte_Array) return Byte_Array;
   function Hash_Sha3_512 (Data : Byte_Array) return Byte_Array;
   function Hmac_Sha256 (Key, Data : Byte_Array) return Byte_Array;
   function Hmac_Sha512 (Key, Data : Byte_Array) return Byte_Array;

   --  Base-64 (sodium_bin2base64 / sodium_base642bin).  The variant selects
   --  libsodium's alphabet and padding; Original is the standard padded
   --  alphabet.  Decode raises Crypto_Error on input invalid for the variant.
   type Base64_Variant is
     (Original, Original_No_Padding, Url_Safe, Url_Safe_No_Padding);
   for Base64_Variant use
     (Original            => 1,
      Original_No_Padding => 3,
      Url_Safe            => 5,
      Url_Safe_No_Padding => 7);

   function Base64_Encode
     (Data    : Byte_Array;
      Variant : Base64_Variant := Original) return String;
   function Base64_Decode
     (S       : String;
      Variant : Base64_Variant := Original) return Byte_Array;

   --  Hex (sodium_bin2hex / sodium_hex2bin).  Decode raises Crypto_Error on
   --  an odd-length or non-hex input.
   function Hex_Encode (Data : Byte_Array) return String;
   function Hex_Decode (S : String) return Byte_Array;

   --  Constant-time comparison.  The Verify_* wrappers raise Constraint_Error
   --  on a wrong-length argument; Constant_Time_Equal takes any equal-length
   --  pair.
   function Verify_16 (A, B : Byte_Array) return Boolean;
   function Verify_32 (A, B : Byte_Array) return Boolean;
   function Verify_64 (A, B : Byte_Array) return Boolean;
   function Constant_Time_Equal (A, B : Byte_Array) return Boolean;

   --  Little-endian big-number helpers over the leading bytes (nonce
   --  management).  Add and Sub require V'Length = B'Length; Compare requires
   --  A'Length = B'Length.  Raise Constraint_Error on a too-short or
   --  mismatched buffer.
   procedure Increment (B : in out Byte_Array);
   procedure Add (B : in out Byte_Array; V : Byte_Array);
   procedure Sub (B : in out Byte_Array; V : Byte_Array);

   --  Constant-time test against zero (sodium_is_zero): True iff every byte
   --  is zero (the empty buffer is all-zero).  Compare orders A against B as
   --  unsigned little-endian integers, returning -1, 0, or 1; unlike
   --  Constant_Time_Equal it is *not* constant-time and is meant for ordering
   --  nonces and counters.
   function Is_Zero (B : Byte_Array) return Boolean;
   function Compare (A, B : Byte_Array) return Integer;

   --  Deterministic wipe (sodium_memzero): zeroes B in a way the compiler
   --  cannot optimize away.
   procedure Memzero (B : in out Byte_Array);

   --  Guarded storage for secrets: page-aligned sodium_malloc memory, pinned
   --  against swap (mlock) by Secure_Alloc/Secure_Alloc_Array -- which raise
   --  Crypto_Error if the region cannot be locked -- and made read-only /
   --  no-access with Protect.  Wipe overwrites with random junk then
   --  sodium_memzero; Secure_Free wipes and releases.  A Secure_Buffer is a
   --  single-owner handle: do not copy it (a copy would alias the same region
   --  and later double-free).
   type Secure_Buffer is private;

   type Protect_Mode is (No_Access, Read_Only, Read_Write);

   function Secure_Alloc (N : Natural) return Secure_Buffer;
   function Secure_Alloc_Array (Count, Size : Natural) return Secure_Buffer;
   procedure Secure_Free (B : in out Secure_Buffer);
   function Length (B : Secure_Buffer) return Natural;
   procedure Fill (B : in out Secure_Buffer; Data : Byte_Array);
   function Contents (B : Secure_Buffer) return Byte_Array;
   procedure Wipe (B : in out Secure_Buffer);
   procedure Mlock (B : Secure_Buffer);
   procedure Munlock (B : Secure_Buffer);
   procedure Protect (B : Secure_Buffer; Mode : Protect_Mode);

   --  Opaque, 64-byte-aligned storage for libsodium's streaming state structs
   --  (crypto_sign_state, crypto_generichash_state, ...).  Child packages use
   --  this as their state type; the C library reads/writes it as its own POD
   --  struct, so callers only ever pass it back by reference.  64 matches
   --  sodium's CRYPTO_ALIGN(64): BLAKE2b's state needs it, and over-alignment
   --  is harmless for the smaller states.
   type State_Buffer (Size : Natural) is record
      Data : Byte_Array (1 .. Size);
   end record;
   for State_Buffer'Alignment use 64;

   --  ChaCha20-Poly1305 seal/open.  Key and Nonce must be Key_Size and
   --  Nonce_Size bytes; Aad may be empty.  Ciphertext has the plaintext
   --  length.  Open raises Crypto_Error on authentication failure.
   function Seal
     (Key, Nonce, Aad, Plaintext : Byte_Array) return Sealed_Text;

   function Open
     (Key, Nonce, Aad : Byte_Array;
      Text            : Sealed_Text) return Byte_Array;

   --  Combined-mode AEAD (crypto_aead_*_encrypt/decrypt): the ciphertext and
   --  tag concatenated into one buffer, Ciphertext || Tag.  Seal_Combined
   --  returns Plaintext'Length + Tag_Size bytes; Open_Combined takes that
   --  buffer and recovers the plaintext, raising Crypto_Error on
   --  authentication failure.  The detached Seal/Open remain for callers that
   --  keep the tag separate.
   function Seal_Combined
     (Key, Nonce, Aad, Plaintext : Byte_Array) return Byte_Array;

   function Open_Combined
     (Key, Nonce, Aad, Ciphertext : Byte_Array) return Byte_Array;

   --  Constant-length deterministic padding (sodium_pad / sodium_unpad).
   --  Pad appends up to Block_Size bytes; Unpad reverses it.
   function Pad (Data : Byte_Array; Block_Size : Positive) return Byte_Array;
   function Unpad (Data : Byte_Array; Block_Size : Positive) return Byte_Array;

   --  CPU feature detection (sodium_runtime_has_*).
   function Runtime_Has_Neon return Boolean;
   function Runtime_Has_Sse2 return Boolean;
   function Runtime_Has_Sse3 return Boolean;
   function Runtime_Has_Ssse3 return Boolean;
   function Runtime_Has_Sse41 return Boolean;
   function Runtime_Has_Avx return Boolean;
   function Runtime_Has_Avx2 return Boolean;
   function Runtime_Has_Avx512f return Boolean;
   function Runtime_Has_Pclmul return Boolean;
   function Runtime_Has_Aesni return Boolean;
   function Runtime_Has_Rdrand return Boolean;

   --  Misuse handler (sodium_set_misuse_handler): install a callback invoked
   --  when libsodium detects misuse (e.g. a reused nonce).  Raises
   --  Crypto_Error if a handler is already installed.
   type Misuse_Handler is access procedure;
   pragma Convention (C, Misuse_Handler);
   procedure Set_Misuse_Handler (Handler : Misuse_Handler);

private

   type Secure_Buffer is record
      Data : System.Address := System.Null_Address;
      Len  : Natural := 0;
   end record;

end Crypto;
