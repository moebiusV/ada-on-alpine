pragma Ada_2022;


--  Password hashing (crypto_pwhash_*, Argon2id/Argon2i and scrypt): derive a
--  key from a password and salt with a tunable ops/memory cost, or produce
--  and verify the self-describing encoded-string form.
package Crypto.Pwhash is

   Salt_Size        : constant := 16;    --  argon2i/id salt
   Str_Size         : constant := 128;   --  argon2 encoded string buffer
   Scrypt_Salt_Size : constant := 32;
   Scrypt_Str_Size  : constant := 102;

   --  Cost presets (argon2).  Interactive is ~64 MiB; raise for offline keys.
   Ops_Interactive : constant := 2;
   Mem_Interactive : constant := 67_108_864;
   Ops_Moderate    : constant := 3;
   Mem_Moderate    : constant := 268_435_456;
   Ops_Sensitive   : constant := 4;
   Mem_Sensitive   : constant := 1_073_741_824;

   Scrypt_Ops_Interactive : constant := 524_288;
   Scrypt_Mem_Interactive : constant := 16_777_216;

   type Algorithm is (Argon2i, Argon2id);
   for Algorithm use (Argon2i => 1, Argon2id => 2);

   --  Argon2: derive Length bytes of key material.
   function Hash
     (Password, Salt : Crypto.Byte_Array;
      Length : Natural;
      Ops, Mem : Natural;
      Alg : Algorithm := Argon2id) return Crypto.Byte_Array;

   --  Argon2 encoded string (self-describing, includes salt and cost).
   function Str_Hash
     (Password : Crypto.Byte_Array; Ops, Mem : Natural) return String;
   function Str_Verify
     (Str : String; Password : Crypto.Byte_Array) return Boolean;
   function Str_Needs_Rehash (Str : String; Ops, Mem : Natural) return Boolean;

   --  scrypt: derive Length bytes of key material.
   function Scrypt_Hash
     (Password, Salt : Crypto.Byte_Array; Length, Ops, Mem : Natural)
      return Crypto.Byte_Array;
   function Scrypt_Str_Hash
     (Password : Crypto.Byte_Array; Ops, Mem : Natural) return String;
   function Scrypt_Str_Verify
     (Str : String; Password : Crypto.Byte_Array) return Boolean;
   function Scrypt_Str_Needs_Rehash
     (Str : String; Ops, Mem : Natural) return Boolean;

end Crypto.Pwhash;
