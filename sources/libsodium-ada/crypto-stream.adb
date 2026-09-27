pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Stream is

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

   function C_Xsalsa20 (C : System.Address; C_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream";

   function C_Xsalsa20_Xor
     (C, M : System.Address; M_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_xor";

   function C_Xchacha20 (C : System.Address; C_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_xchacha20";

   function C_Xchacha20_Xor
     (C, M : System.Address; M_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_xchacha20_xor";

   function C_Chacha20 (C : System.Address; C_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_chacha20";

   function C_Chacha20_Xor
     (C, M : System.Address; M_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_chacha20_xor";

   function C_Chacha20_Ietf
     (C : System.Address; C_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_chacha20_ietf";

   function C_Chacha20_Ietf_Xor
     (C, M : System.Address; M_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_stream_chacha20_ietf_xor";

   function C_Salsa20 (C : System.Address; C_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_salsa20";

   function C_Salsa20_Xor
     (C, M : System.Address; M_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_salsa20_xor";

   function C_Salsa2012 (C : System.Address; C_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_salsa2012";

   function C_Salsa2012_Xor
     (C, M : System.Address; M_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_salsa2012_xor";

   function C_Salsa208 (C : System.Address; C_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_salsa208";

   function C_Salsa208_Xor
     (C, M : System.Address; M_Len : ULL; N, K : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_stream_salsa208_xor";

   function Nonce_Size (Kind : Stream_Kind) return Natural is
     (case Kind is
        when XSalsa20 | XChacha20 => 24,
        when ChaCha20_Ietf => 12,
        when ChaCha20 | Salsa20 | Salsa2012 | Salsa208 => 8);

   function Keystream
     (Length : Natural;
      Nonce, Key : Crypto.Byte_Array;
      Kind : Stream_Kind := XSalsa20) return Crypto.Byte_Array
   is
      C  : Crypto.Byte_Array (1 .. Length);
      Rc : Interfaces.C.int;
   begin
      if Key'Length /= Key_Size then
         Fail ("key size");
      end if;
      if Nonce'Length /= Nonce_Size (Kind) then
         Fail ("nonce size");
      end if;
      case Kind is
         when XSalsa20     => Rc := C_Xsalsa20 (C (1)'Address, ULL (Length), Addr (Nonce), Addr (Key));
         when XChacha20    => Rc := C_Xchacha20 (C (1)'Address, ULL (Length), Addr (Nonce), Addr (Key));
         when ChaCha20     => Rc := C_Chacha20 (C (1)'Address, ULL (Length), Addr (Nonce), Addr (Key));
         when ChaCha20_Ietf => Rc := C_Chacha20_Ietf (C (1)'Address, ULL (Length), Addr (Nonce), Addr (Key));
         when Salsa20      => Rc := C_Salsa20 (C (1)'Address, ULL (Length), Addr (Nonce), Addr (Key));
         when Salsa2012    => Rc := C_Salsa2012 (C (1)'Address, ULL (Length), Addr (Nonce), Addr (Key));
         when Salsa208     => Rc := C_Salsa208 (C (1)'Address, ULL (Length), Addr (Nonce), Addr (Key));
      end case;
      if Rc /= 0 then
         Fail ("stream failed");
      end if;
      return C;
   end Keystream;

   function Encrypt
     (Message : Crypto.Byte_Array;
      Nonce, Key : Crypto.Byte_Array;
      Kind : Stream_Kind := XSalsa20) return Crypto.Byte_Array
   is
      C  : Crypto.Byte_Array (1 .. Message'Length);
      Rc : Interfaces.C.int;
   begin
      if Key'Length /= Key_Size then
         Fail ("key size");
      end if;
      if Nonce'Length /= Nonce_Size (Kind) then
         Fail ("nonce size");
      end if;
      case Kind is
         when XSalsa20     => Rc := C_Xsalsa20_Xor (C (1)'Address, Addr (Message), ULL (Message'Length), Addr (Nonce), Addr (Key));
         when XChacha20    => Rc := C_Xchacha20_Xor (C (1)'Address, Addr (Message), ULL (Message'Length), Addr (Nonce), Addr (Key));
         when ChaCha20     => Rc := C_Chacha20_Xor (C (1)'Address, Addr (Message), ULL (Message'Length), Addr (Nonce), Addr (Key));
         when ChaCha20_Ietf => Rc := C_Chacha20_Ietf_Xor (C (1)'Address, Addr (Message), ULL (Message'Length), Addr (Nonce), Addr (Key));
         when Salsa20      => Rc := C_Salsa20_Xor (C (1)'Address, Addr (Message), ULL (Message'Length), Addr (Nonce), Addr (Key));
         when Salsa2012    => Rc := C_Salsa2012_Xor (C (1)'Address, Addr (Message), ULL (Message'Length), Addr (Nonce), Addr (Key));
         when Salsa208     => Rc := C_Salsa208_Xor (C (1)'Address, Addr (Message), ULL (Message'Length), Addr (Nonce), Addr (Key));
      end case;
      if Rc /= 0 then
         Fail ("stream xor failed");
      end if;
      return C;
   end Encrypt;

end Crypto.Stream;
