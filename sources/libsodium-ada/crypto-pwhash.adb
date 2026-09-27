pragma Ada_2022;

with Interfaces.C;
with Interfaces.C.Strings;
with System;

package body Crypto.Pwhash is

   use type Interfaces.C.int;

   type ULL is mod 2 ** 64;
   pragma Convention (C, ULL);

   function Addr (B : Crypto.Byte_Array) return System.Address is
   begin
      if B'Length = 0 then
         return System.Null_Address;
      end if;
      return B (B'First)'Address;
   end Addr;

   procedure Fail (S : String) is
   begin
      raise Crypto.Crypto_Error with S;
   end Fail;

   function C_Hash
     (Dg : System.Address; Dg_Len : ULL;
      Passwd : System.Address; Passwd_Len : ULL;
      Salt : System.Address;
      Ops : ULL; Mem : Interfaces.C.size_t;
      Alg : Interfaces.C.int) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_pwhash";

   function C_Str_Hash
     (Dg : System.Address; Passwd : System.Address; Passwd_Len : ULL;
      Ops : ULL; Mem : Interfaces.C.size_t) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_pwhash_str";

   function C_Str_Verify
     (Str : Interfaces.C.Strings.chars_ptr;
      Passwd : System.Address; Passwd_Len : ULL) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_pwhash_str_verify";

   function C_Str_Needs_Rehash
     (Str : Interfaces.C.Strings.chars_ptr;
      Ops : ULL; Mem : Interfaces.C.size_t) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_pwhash_str_needs_rehash";

   function C_Scrypt_Hash
     (Dg : System.Address; Dg_Len : ULL;
      Passwd : System.Address; Passwd_Len : ULL;
      Salt : System.Address;
      Ops : ULL; Mem : Interfaces.C.size_t) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_pwhash_scryptsalsa208sha256";

   function C_Scrypt_Str_Hash
     (Dg : System.Address; Passwd : System.Address; Passwd_Len : ULL;
      Ops : ULL; Mem : Interfaces.C.size_t) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_pwhash_scryptsalsa208sha256_str";

   function C_Scrypt_Str_Verify
     (Str : Interfaces.C.Strings.chars_ptr;
      Passwd : System.Address; Passwd_Len : ULL) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_pwhash_scryptsalsa208sha256_str_verify";

   function Hash
     (Password, Salt : Crypto.Byte_Array;
      Length : Natural;
      Ops, Mem : Natural;
      Alg : Algorithm := Argon2id) return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. Length);
   begin
      if Salt'Length /= Salt_Size then
         Fail ("salt size");
      end if;
      if C_Hash (D (1)'Address, ULL (Length),
                 Addr (Password), ULL (Password'Length),
                 Addr (Salt), ULL (Ops), Interfaces.C.size_t (Mem),
                 Interfaces.C.int (Algorithm'Enum_Rep (Alg))) /= 0
      then
         Fail ("pwhash failed");
      end if;
      return D;
   end Hash;

   function Str_Hash (Password : Crypto.Byte_Array; Ops, Mem : Natural)
      return String
   is
      use Interfaces.C;
      Buf : aliased char_array (0 .. size_t (Str_Size));
      Rc  : int;
   begin
      Rc := C_Str_Hash (Buf (Buf'First)'Address, Addr (Password),
                        ULL (Password'Length), ULL (Ops), size_t (Mem));
      if Rc /= 0 then
         Fail ("pwhash str failed");
      end if;
      return To_Ada (Buf);
   end Str_Hash;

   function Str_Verify (Str : String; Password : Crypto.Byte_Array)
      return Boolean
   is
      use Interfaces.C.Strings;
      C  : chars_ptr := New_String (Str);
      Rc : Interfaces.C.int;
   begin
      Rc := C_Str_Verify (C, Addr (Password), ULL (Password'Length));
      Free (C);
      return Rc = 0;
   end Str_Verify;

   function Str_Needs_Rehash (Str : String; Ops, Mem : Natural)
      return Boolean
   is
      use Interfaces.C;
      use Interfaces.C.Strings;
      C  : chars_ptr := New_String (Str);
      Rc : Interfaces.C.int;
   begin
      Rc := C_Str_Needs_Rehash (C, ULL (Ops), size_t (Mem));
      Free (C);
      return Rc /= 0;
   end Str_Needs_Rehash;

   function Scrypt_Hash
     (Password, Salt : Crypto.Byte_Array; Length, Ops, Mem : Natural)
      return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. Length);
   begin
      if Salt'Length /= Scrypt_Salt_Size then
         Fail ("scrypt salt size");
      end if;
      if C_Scrypt_Hash (D (1)'Address, ULL (Length),
                        Addr (Password), ULL (Password'Length),
                        Addr (Salt), ULL (Ops), Interfaces.C.size_t (Mem)) /= 0
      then
         Fail ("scrypt hash failed");
      end if;
      return D;
   end Scrypt_Hash;

   function Scrypt_Str_Hash (Password : Crypto.Byte_Array; Ops, Mem : Natural)
      return String
   is
      use Interfaces.C;
      Buf : aliased char_array (0 .. size_t (Scrypt_Str_Size));
      Rc  : int;
   begin
      Rc := C_Scrypt_Str_Hash (Buf (Buf'First)'Address, Addr (Password),
                               ULL (Password'Length), ULL (Ops), size_t (Mem));
      if Rc /= 0 then
         Fail ("scrypt str failed");
      end if;
      return To_Ada (Buf);
   end Scrypt_Str_Hash;

   function Scrypt_Str_Verify (Str : String; Password : Crypto.Byte_Array)
      return Boolean
   is
      use Interfaces.C.Strings;
      C  : chars_ptr := New_String (Str);
      Rc : Interfaces.C.int;
   begin
      Rc := C_Scrypt_Str_Verify (C, Addr (Password), ULL (Password'Length));
      Free (C);
      return Rc = 0;
   end Scrypt_Str_Verify;

end Crypto.Pwhash;
