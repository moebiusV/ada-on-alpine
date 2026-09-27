pragma Ada_2022;

with Interfaces.C;
with Interfaces.C.Strings;

package body Crypto is

   use type Ada.Streams.Stream_Element;
   use type Interfaces.C.int;
   use type System.Address;

   --  64-bit unsigned, matching libsodium's unsigned long long lengths.
   type ULL is mod 2 ** 64;
   pragma Convention (C, ULL);

   --  Empty byte array, for zero-length results.
   Empty : constant Byte_Array (1 .. 0) := [others => 0];

   function Sodium_Init return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_init";

   function Sodium_Version_String return Interfaces.C.Strings.chars_ptr
     with Import, Convention => C, External_Name => "sodium_version_string";

   function Sodium_Library_Version_Major return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "sodium_library_version_major";

   function Sodium_Library_Version_Minor return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "sodium_library_version_minor";

   procedure Randombytes_Buf (Buf : System.Address; Size : Interfaces.C.size_t)
     with Import, Convention => C, External_Name => "randombytes_buf";

   function Randombytes_Uniform
     (Upper_Bound : Interfaces.Unsigned_32) return Interfaces.Unsigned_32
     with Import, Convention => C, External_Name => "randombytes_uniform";

   procedure Randombytes_Buf_Deterministic
     (Buf  : System.Address;
      Size : Interfaces.C.size_t;
      Seed : System.Address)
     with Import, Convention => C,
          External_Name => "randombytes_buf_deterministic";

   function Crypto_Hash_Sha256
     (Digest  : System.Address;
      Msg     : System.Address;
      Msg_Len : ULL)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha256";

   function Crypto_Hash_Sha512
     (Digest  : System.Address;
      Msg     : System.Address;
      Msg_Len : ULL)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_hash_sha512";

   function Crypto_Verify_16 (X, Y : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_verify_16";

   function Crypto_Verify_32 (X, Y : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_verify_32";

   function Crypto_Verify_64 (X, Y : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_verify_64";

   function Sodium_Memcmp
     (B1, B2 : System.Address; Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_memcmp";

   procedure Sodium_Increment (N : System.Address; Nlen : Interfaces.C.size_t)
     with Import, Convention => C, External_Name => "sodium_increment";

   procedure Sodium_Add
     (A, B : System.Address; Len : Interfaces.C.size_t)
     with Import, Convention => C, External_Name => "sodium_add";

   procedure Sodium_Memzero (Pnt : System.Address; Len : Interfaces.C.size_t)
     with Import, Convention => C, External_Name => "sodium_memzero";

   function Sodium_Bin2Base64
     (B64        : System.Address;
      B64_Maxlen : Interfaces.C.size_t;
      Bin        : System.Address;
      Bin_Len    : Interfaces.C.size_t;
      Variant    : Interfaces.C.int)
     return Interfaces.C.Strings.chars_ptr
     with Import, Convention => C, External_Name => "sodium_bin2base64";

   function Sodium_Base642Bin
     (Bin        : System.Address;
      Bin_Maxlen : Interfaces.C.size_t;
      B64        : System.Address;
      B64_Len    : Interfaces.C.size_t;
      Ignore     : System.Address;
      Bin_Len    : System.Address;
      B64_End    : System.Address;
      Variant    : Interfaces.C.int)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_base642bin";

   function Sodium_Bin2Hex
     (Hex        : System.Address;
      Hex_Maxlen : Interfaces.C.size_t;
      Bin        : System.Address;
      Bin_Len    : Interfaces.C.size_t)
     return Interfaces.C.Strings.chars_ptr
     with Import, Convention => C, External_Name => "sodium_bin2hex";

   function Sodium_Hex2Bin
     (Bin        : System.Address;
      Bin_Maxlen : Interfaces.C.size_t;
      Hex        : System.Address;
      Hex_Len    : Interfaces.C.size_t;
      Ignore     : System.Address;
      Bin_Len    : System.Address;
      Hex_End    : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_hex2bin";

   function Sodium_Malloc (N : Interfaces.C.size_t) return System.Address
     with Import, Convention => C, External_Name => "sodium_malloc";

   function Sodium_Allocarray
     (Count, Size : Interfaces.C.size_t) return System.Address
     with Import, Convention => C, External_Name => "sodium_allocarray";

   procedure Sodium_Free (P : System.Address)
     with Import, Convention => C, External_Name => "sodium_free";

   function Sodium_Mlock
     (P : System.Address; N : Interfaces.C.size_t) return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_mlock";

   function Sodium_Munlock
     (P : System.Address; N : Interfaces.C.size_t) return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_munlock";

   function Sodium_Mprotect_Noaccess (P : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_mprotect_noaccess";

   function Sodium_Mprotect_Readonly (P : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_mprotect_readonly";

   function Sodium_Mprotect_Readwrite (P : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "sodium_mprotect_readwrite";

   procedure C_Memcpy
     (Dst, Src : System.Address; N : Interfaces.C.size_t)
     with Import, Convention => C, External_Name => "memcpy";

   function Crypto_Aead_Chacha20poly1305_Ietf_Encrypt_Detached
     (C       : System.Address;
      Mac     : System.Address;
      Mac_Len : System.Address;
      M       : System.Address;
      M_Len   : ULL;
      Ad      : System.Address;
      Ad_Len  : ULL;
      Nsec    : System.Address;
      Npub    : System.Address;
      K       : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name =>
            "crypto_aead_chacha20poly1305_ietf_encrypt_detached";

   function Crypto_Aead_Chacha20poly1305_Ietf_Decrypt_Detached
     (M      : System.Address;
      Nsec   : System.Address;
      C      : System.Address;
      C_Len  : ULL;
      Mac    : System.Address;
      Ad     : System.Address;
      Ad_Len : ULL;
      Npub   : System.Address;
      K      : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name =>
            "crypto_aead_chacha20poly1305_ietf_decrypt_detached";

   function Sodium_Pad
     (Padded_Len   : System.Address;
      Buf          : System.Address;
      Unpadded_Len : Interfaces.C.size_t;
      Block_Size   : Interfaces.C.size_t;
      Max_Len      : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_pad";

   function Sodium_Unpad
     (Unpadded_Len : System.Address;
      Buf          : System.Address;
      Padded_Len   : Interfaces.C.size_t;
      Block_Size   : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_unpad";

   function C_Runtime_Neon return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_neon";
   function C_Runtime_Sse2 return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_sse2";
   function C_Runtime_Sse3 return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_sse3";
   function C_Runtime_Ssse3 return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_ssse3";
   function C_Runtime_Sse41 return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_sse41";
   function C_Runtime_Avx return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_avx";
   function C_Runtime_Avx2 return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_avx2";
   function C_Runtime_Avx512f return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_avx512f";
   function C_Runtime_Pclmul return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_pclmul";
   function C_Runtime_Aesni return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_aesni";
   function C_Runtime_Rdrand return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_runtime_has_rdrand";

   function C_Set_Misuse_Handler (H : Misuse_Handler) return Interfaces.C.int
     with Import, Convention => C, External_Name => "sodium_set_misuse_handler";

   --  Address of a byte array, or a null pointer when empty.
   function Addr (B : Byte_Array) return System.Address is
   begin
      if B'Length = 0 then
         return System.Null_Address;
      end if;
      return B (B'First)'Address;
   end Addr;

   procedure Init is
      Rc : constant Interfaces.C.int := Sodium_Init;
   begin
      if Rc < 0 then
         raise Crypto_Error with "sodium_init failed";
      end if;
   end Init;

   function Version_String return String is
      use Interfaces.C.Strings;
   begin
      return Value (Sodium_Version_String);
   end Version_String;

   function Version_Major return Natural is
     (Natural (Sodium_Library_Version_Major));

   function Version_Minor return Natural is
     (Natural (Sodium_Library_Version_Minor));

   function Random (N : Natural) return Byte_Array is
      Result : Byte_Array (1 .. N);
   begin
      if N > 0 then
         Randombytes_Buf
           (Result (Result'First)'Address, Interfaces.C.size_t (N));
      end if;
      return Result;
   end Random;

   function Random_Uniform (Upper_Bound : Interfaces.Unsigned_32)
      return Interfaces.Unsigned_32 is
   begin
      return Randombytes_Uniform (Upper_Bound);
   end Random_Uniform;

   function Random_Deterministic (N : Natural; Seed : Byte_Array)
      return Byte_Array
   is
      Result : Byte_Array (1 .. N);
   begin
      if Seed'Length /= Seed_Size then
         raise Crypto_Error with "seed size";
      end if;
      if N > 0 then
         Randombytes_Buf_Deterministic
           (Result (Result'First)'Address, Interfaces.C.size_t (N),
            Addr (Seed));
      end if;
      return Result;
   end Random_Deterministic;

   function Hash_Sha256 (Data : Byte_Array) return Byte_Array is
      Digest : Byte_Array (1 .. Hash256_Size);
      Rc     : Interfaces.C.int;
   begin
      Rc := Crypto_Hash_Sha256
        (Digest (1)'Address, Addr (Data), ULL (Data'Length));
      if Rc /= 0 then
         raise Crypto_Error with "sha256 failed";
      end if;
      return Digest;
   end Hash_Sha256;

   function Hash_Sha512 (Data : Byte_Array) return Byte_Array is
      Digest : Byte_Array (1 .. Hash512_Size);
      Rc     : Interfaces.C.int;
   begin
      Rc := Crypto_Hash_Sha512
        (Digest (1)'Address, Addr (Data), ULL (Data'Length));
      if Rc /= 0 then
         raise Crypto_Error with "sha512 failed";
      end if;
      return Digest;
   end Hash_Sha512;

   procedure Memzero (B : in out Byte_Array) is
   begin
      if B'Length > 0 then
         Sodium_Memzero (B (B'First)'Address, Interfaces.C.size_t (B'Length));
      end if;
   end Memzero;

   --  RFC 2104 HMAC, composed over libsodium's SHA-2 hash so keys of any
   --  length follow the standard (crypto_auth_hmacsha* fix the key width).
   --  Only the pad-XOR-and-hash composition is spelled out here.
   function Hmac
     (Key, Data  : Byte_Array;
      Block_Size : Positive;
      Digest_Size : Positive) return Byte_Array
   is
      pragma Warnings (Off, "could be declared constant");
      Key_Norm   : aliased Byte_Array (1 .. Block_Size) := [others => 0];
      Inner_Hash : aliased Byte_Array (1 .. Digest_Size) := [others => 0];
      Result     : aliased Byte_Array (1 .. Digest_Size) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      Inner      : Byte_Array (1 .. Block_Size + Data'Length);
      Outer      : Byte_Array (1 .. Block_Size + Digest_Size);
      Rc         : Interfaces.C.int;
   begin
      if Key'Length > Block_Size then
         if Block_Size = 128 then
            Rc := Crypto_Hash_Sha512
              (Key_Norm (1)'Address, Addr (Key), ULL (Key'Length));
         else
            Rc := Crypto_Hash_Sha256
              (Key_Norm (1)'Address, Addr (Key), ULL (Key'Length));
         end if;
         if Rc /= 0 then
            raise Crypto_Error with "key-hash failed";
         end if;
      elsif Key'Length > 0 then
         Key_Norm (1 .. Key'Length) := Key;
      end if;

      for I in 1 .. Block_Size loop
         Inner (I) := Key_Norm (I) xor 16#36#;
      end loop;
      Inner (Block_Size + 1 .. Inner'Last) := Data;
      if Block_Size = 128 then
         Rc := Crypto_Hash_Sha512
           (Inner_Hash (1)'Address, Inner (1)'Address, ULL (Inner'Length));
      else
         Rc := Crypto_Hash_Sha256
           (Inner_Hash (1)'Address, Inner (1)'Address, ULL (Inner'Length));
      end if;
      if Rc /= 0 then
         raise Crypto_Error with "inner-hash failed";
      end if;

      for I in 1 .. Block_Size loop
         Outer (I) := Key_Norm (I) xor 16#5c#;
      end loop;
      Outer (Block_Size + 1 .. Outer'Last) := Inner_Hash;
      if Block_Size = 128 then
         Rc := Crypto_Hash_Sha512
           (Result (1)'Address, Outer (1)'Address, ULL (Outer'Length));
      else
         Rc := Crypto_Hash_Sha256
           (Result (1)'Address, Outer (1)'Address, ULL (Outer'Length));
      end if;
      if Rc /= 0 then
         raise Crypto_Error with "outer-hash failed";
      end if;

      return Result;
   end Hmac;

   function Hmac_Sha256 (Key, Data : Byte_Array) return Byte_Array is
     (Hmac (Key, Data, 64, Hmac_Size));

   function Hmac_Sha512 (Key, Data : Byte_Array) return Byte_Array is
     (Hmac (Key, Data, 128, Hash512_Size));

   function Base64_Encode
     (Data    : Byte_Array;
      Variant : Base64_Variant := Original) return String
   is
      use Interfaces.C;
      use Interfaces.C.Strings;
      Enc_Len : constant size_t := size_t (((Data'Length + 2) / 3) * 4);
      Buf     : aliased char_array (0 .. Enc_Len);
      Rc      : chars_ptr;
   begin
      if Data'Length = 0 then
         return "";
      end if;
      Rc := Sodium_Bin2Base64
        (Buf (Buf'First)'Address, size_t (Buf'Length),
         Addr (Data), size_t (Data'Length),
         int (Base64_Variant'Enum_Rep (Variant)));
      if Rc = Null_Ptr then
         raise Crypto_Error with "base64 encode failed";
      end if;
      return Value (Rc);
   end Base64_Encode;

   function Base64_Decode
     (S       : String;
      Variant : Base64_Variant := Original) return Byte_Array
   is
      use Interfaces.C;
      Max_Len : constant Natural := (S'Length / 4) * 3 + 3;
      Bin     : Byte_Array (1 .. Max_Len);
      Bin_Len : aliased size_t := 0;
      Rc      : int;
   begin
      if S'Length = 0 then
         return Empty;
      end if;
      Rc := Sodium_Base642Bin
        (Bin (Bin'First)'Address, size_t (Bin'Length),
         S (S'First)'Address, size_t (S'Length),
         System.Null_Address, Bin_Len'Address, System.Null_Address,
         int (Base64_Variant'Enum_Rep (Variant)));
      if Rc /= 0 then
         raise Crypto_Error with "base64 decode failed";
      end if;
      declare
         Result : Byte_Array (1 .. Natural (Bin_Len));
      begin
         Result := Bin (1 .. Natural (Bin_Len));
         return Result;
      end;
   end Base64_Decode;

   function Hex_Encode (Data : Byte_Array) return String is
      use Interfaces.C;
      use Interfaces.C.Strings;
      Buf : aliased char_array (0 .. size_t (Data'Length * 2));
      Rc  : chars_ptr;
   begin
      if Data'Length = 0 then
         return "";
      end if;
      Rc := Sodium_Bin2Hex
        (Buf (Buf'First)'Address, size_t (Buf'Length),
         Addr (Data), size_t (Data'Length));
      if Rc = Null_Ptr then
         raise Crypto_Error with "hex encode failed";
      end if;
      return Value (Rc);
   end Hex_Encode;

   function Hex_Decode (S : String) return Byte_Array is
      use Interfaces.C;
      Bin     : Byte_Array (1 .. S'Length / 2);
      Bin_Len : aliased size_t := 0;
      Rc      : int;
   begin
      if S'Length = 0 then
         return Empty;
      end if;
      if S'Length mod 2 /= 0 then
         raise Crypto_Error with "odd-length hex input";
      end if;
      Rc := Sodium_Hex2Bin
        (Bin (Bin'First)'Address, size_t (Bin'Length),
         S (S'First)'Address, size_t (S'Length),
         System.Null_Address, Bin_Len'Address, System.Null_Address);
      if Rc /= 0 then
         raise Crypto_Error with "hex decode failed";
      end if;
      declare
         Result : Byte_Array (1 .. Natural (Bin_Len));
      begin
         Result := Bin (1 .. Natural (Bin_Len));
         return Result;
      end;
   end Hex_Decode;

   function Verify_16 (A, B : Byte_Array) return Boolean is
   begin
      if A'Length /= 16 or else B'Length /= 16 then
         raise Constraint_Error with "verify16 length";
      end if;
      return Crypto_Verify_16 (Addr (A), Addr (B)) = 0;
   end Verify_16;

   function Verify_32 (A, B : Byte_Array) return Boolean is
   begin
      if A'Length /= 32 or else B'Length /= 32 then
         raise Constraint_Error with "verify32 length";
      end if;
      return Crypto_Verify_32 (Addr (A), Addr (B)) = 0;
   end Verify_32;

   function Verify_64 (A, B : Byte_Array) return Boolean is
   begin
      if A'Length /= 64 or else B'Length /= 64 then
         raise Constraint_Error with "verify64 length";
      end if;
      return Crypto_Verify_64 (Addr (A), Addr (B)) = 0;
   end Verify_64;

   function Constant_Time_Equal (A, B : Byte_Array) return Boolean is
   begin
      if A'Length /= B'Length then
         raise Constraint_Error with "length mismatch";
      end if;
      return Sodium_Memcmp
        (Addr (A), Addr (B), Interfaces.C.size_t (A'Length)) = 0;
   end Constant_Time_Equal;

   procedure Increment (B : in out Byte_Array) is
   begin
      if B'Length = 0 then
         raise Constraint_Error with "increment empty";
      end if;
      Sodium_Increment
        (B (B'First)'Address, Interfaces.C.size_t (B'Length));
   end Increment;

   procedure Add (B : in out Byte_Array; V : Byte_Array) is
   begin
      if B'Length = 0 or else B'Length /= V'Length then
         raise Constraint_Error with "add length";
      end if;
      Sodium_Add
        (B (B'First)'Address, Addr (V), Interfaces.C.size_t (B'Length));
   end Add;

   function Secure_Alloc (N : Natural) return Secure_Buffer is
   begin
      if N = 0 then
         return (Data => System.Null_Address, Len => 0);
      end if;
      declare
         P : constant System.Address :=
           Sodium_Malloc (Interfaces.C.size_t (N));
      begin
         if P = System.Null_Address then
            raise Crypto_Error with "sodium_malloc failed";
         end if;
         Sodium_Memzero (P, Interfaces.C.size_t (N));
         return (Data => P, Len => N);
      end;
   end Secure_Alloc;

   function Secure_Alloc_Array (Count, Size : Natural) return Secure_Buffer is
   begin
      if Count = 0 or else Size = 0 then
         return (Data => System.Null_Address, Len => 0);
      end if;
      declare
         P : constant System.Address := Sodium_Allocarray
           (Interfaces.C.size_t (Count), Interfaces.C.size_t (Size));
         N : constant Natural := Count * Size;
      begin
         if P = System.Null_Address then
            raise Crypto_Error with "sodium_allocarray failed";
         end if;
         Sodium_Memzero (P, Interfaces.C.size_t (N));
         return (Data => P, Len => N);
      end;
   end Secure_Alloc_Array;

   procedure Secure_Free (B : in out Secure_Buffer) is
   begin
      if B.Data /= System.Null_Address then
         Wipe (B);
         Sodium_Free (B.Data);
         B.Data := System.Null_Address;
         B.Len := 0;
      end if;
   end Secure_Free;

   function Length (B : Secure_Buffer) return Natural is (B.Len);

   procedure Fill (B : in out Secure_Buffer; Data : Byte_Array) is
   begin
      if Data'Length /= B.Len then
         raise Crypto_Error with "secure buffer length mismatch";
      end if;
      if Data'Length > 0 then
         C_Memcpy
           (B.Data, Addr (Data), Interfaces.C.size_t (Data'Length));
      end if;
   end Fill;

   function Contents (B : Secure_Buffer) return Byte_Array is
      Result : Byte_Array (1 .. B.Len);
   begin
      if B.Len > 0 then
         C_Memcpy
           (Result (Result'First)'Address, B.Data,
            Interfaces.C.size_t (B.Len));
      end if;
      return Result;
   end Contents;

   procedure Wipe (B : in out Secure_Buffer) is
      Junk : constant Byte_Array := Random (B.Len);
   begin
      if B.Data /= System.Null_Address and then B.Len > 0 then
         C_Memcpy (B.Data, Addr (Junk), Interfaces.C.size_t (B.Len));
         Sodium_Memzero (B.Data, Interfaces.C.size_t (B.Len));
      end if;
   end Wipe;

   procedure Mlock (B : Secure_Buffer) is
   begin
      if B.Data /= System.Null_Address
        and then Sodium_Mlock (B.Data, Interfaces.C.size_t (B.Len)) /= 0
      then
         raise Crypto_Error with "sodium_mlock failed";
      end if;
   end Mlock;

   procedure Munlock (B : Secure_Buffer) is
   begin
      if B.Data /= System.Null_Address
        and then Sodium_Munlock (B.Data, Interfaces.C.size_t (B.Len)) /= 0
      then
         raise Crypto_Error with "sodium_munlock failed";
      end if;
   end Munlock;

   procedure Protect (B : Secure_Buffer; Mode : Protect_Mode) is
      Rc : Interfaces.C.int := 0;
   begin
      if B.Data = System.Null_Address then
         return;
      end if;
      case Mode is
         when No_Access => Rc := Sodium_Mprotect_Noaccess (B.Data);
         when Read_Only => Rc := Sodium_Mprotect_Readonly (B.Data);
         when Read_Write => Rc := Sodium_Mprotect_Readwrite (B.Data);
      end case;
      if Rc /= 0 then
         raise Crypto_Error with "sodium_mprotect failed";
      end if;
   end Protect;

   function Seal
     (Key, Nonce, Aad, Plaintext : Byte_Array) return Sealed_Text
   is
      pragma Warnings (Off, "could be declared constant");
      Cipher  : aliased Byte_Array (Plaintext'Range) := [others => 0];
      Tag     : aliased Byte_Array (1 .. Tag_Size) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      Mac_Len : aliased ULL := ULL (Tag_Size);
      Rc      : Interfaces.C.int;
   begin
      if Key'Length /= Key_Size or else Nonce'Length /= Nonce_Size then
         raise Crypto_Error with "bad key or nonce size";
      end if;
      Rc := Crypto_Aead_Chacha20poly1305_Ietf_Encrypt_Detached
        (Addr (Cipher), Addr (Tag), Mac_Len'Address,
         Addr (Plaintext), ULL (Plaintext'Length),
         Addr (Aad), ULL (Aad'Length),
         System.Null_Address, Addr (Nonce), Addr (Key));
      if Rc /= 0 then
         raise Crypto_Error with "aead encrypt failed";
      end if;
      return Sealed_Text'
        (Length => Cipher'Length, Ciphertext => Cipher, Tag => Tag);
   end Seal;

   function Open
     (Key, Nonce, Aad : Byte_Array;
      Text            : Sealed_Text) return Byte_Array
   is
      pragma Warnings (Off, "could be declared constant");
      Plain : aliased Byte_Array (Text.Ciphertext'Range) := [others => 0];
      pragma Warnings (On, "could be declared constant");
      Rc    : Interfaces.C.int;
   begin
      if Key'Length /= Key_Size or else Nonce'Length /= Nonce_Size then
         raise Crypto_Error with "bad key or nonce size";
      end if;
      Rc := Crypto_Aead_Chacha20poly1305_Ietf_Decrypt_Detached
        (Addr (Plain), System.Null_Address,
         Addr (Text.Ciphertext), ULL (Text.Ciphertext'Length),
         Addr (Text.Tag),
         Addr (Aad), ULL (Aad'Length),
         Addr (Nonce), Addr (Key));
      if Rc /= 0 then
         raise Crypto_Error with "authentication failed";
      end if;
      return Plain;
   end Open;

   function Pad (Data : Byte_Array; Block_Size : Positive) return Byte_Array is
      Buf    : Byte_Array (1 .. Data'Length + Block_Size);
      Padded : aliased Interfaces.C.size_t := 0;
   begin
      if Data'Length > 0 then
         C_Memcpy (Buf (1)'Address, Addr (Data),
                   Interfaces.C.size_t (Data'Length));
      end if;
      if Sodium_Pad (Padded'Address, Buf (1)'Address,
                     Interfaces.C.size_t (Data'Length),
                     Interfaces.C.size_t (Block_Size),
                     Interfaces.C.size_t (Buf'Length)) /= 0
      then
         raise Crypto_Error with "pad failed";
      end if;
      declare
         Result : Byte_Array (1 .. Natural (Padded));
      begin
         Result := Buf (1 .. Natural (Padded));
         return Result;
      end;
   end Pad;

   function Unpad (Data : Byte_Array; Block_Size : Positive)
      return Byte_Array
   is
      Unpadded : aliased Interfaces.C.size_t := 0;
   begin
      if Sodium_Unpad (Unpadded'Address, Addr (Data),
                       Interfaces.C.size_t (Data'Length),
                       Interfaces.C.size_t (Block_Size)) /= 0
      then
         raise Crypto_Error with "unpad failed";
      end if;
      declare
         Result : Byte_Array (1 .. Natural (Unpadded));
      begin
         Result := Data (1 .. Natural (Unpadded));
         return Result;
      end;
   end Unpad;

   function Runtime_Has_Neon return Boolean is (C_Runtime_Neon /= 0);
   function Runtime_Has_Sse2 return Boolean is (C_Runtime_Sse2 /= 0);
   function Runtime_Has_Sse3 return Boolean is (C_Runtime_Sse3 /= 0);
   function Runtime_Has_Ssse3 return Boolean is (C_Runtime_Ssse3 /= 0);
   function Runtime_Has_Sse41 return Boolean is (C_Runtime_Sse41 /= 0);
   function Runtime_Has_Avx return Boolean is (C_Runtime_Avx /= 0);
   function Runtime_Has_Avx2 return Boolean is (C_Runtime_Avx2 /= 0);
   function Runtime_Has_Avx512f return Boolean is (C_Runtime_Avx512f /= 0);
   function Runtime_Has_Pclmul return Boolean is (C_Runtime_Pclmul /= 0);
   function Runtime_Has_Aesni return Boolean is (C_Runtime_Aesni /= 0);
   function Runtime_Has_Rdrand return Boolean is (C_Runtime_Rdrand /= 0);

   procedure Set_Misuse_Handler (Handler : Misuse_Handler) is
   begin
      if C_Set_Misuse_Handler (Handler) /= 0 then
         raise Crypto_Error with "misuse handler already set";
      end if;
   end Set_Misuse_Handler;

end Crypto;
