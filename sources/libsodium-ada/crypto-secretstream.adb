pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Secretstream is

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

   procedure C_Keygen (K : System.Address)
     with Import, Convention => C,
          External_Name => "crypto_secretstream_xchacha20poly1305_keygen";

   function C_Init_Push
     (State, Header, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_secretstream_xchacha20poly1305_init_push";

   function C_Push
     (State : System.Address;
      C     : System.Address; C_Len : System.Address;
      M     : System.Address; M_Len : ULL;
      Ad    : System.Address; Ad_Len : ULL;
      Tag   : Interfaces.Unsigned_8) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_secretstream_xchacha20poly1305_push";

   function C_Init_Pull
     (State, Header, K : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_secretstream_xchacha20poly1305_init_pull";

   function C_Pull
     (State : System.Address;
      M     : System.Address; M_Len : System.Address;
      Tag   : System.Address;
      C     : System.Address; C_Len : ULL;
      Ad    : System.Address; Ad_Len : ULL) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_secretstream_xchacha20poly1305_pull";

   function Keygen return Crypto.Byte_Array is
      K : Crypto.Byte_Array (1 .. Key_Size);
   begin
      C_Keygen (K (1)'Address);
      return K;
   end Keygen;

   function Init_Push (Key : Crypto.Byte_Array) return Push_Init is
      P : Push_Init;
   begin
      if Key'Length /= Key_Size then
         Fail ("key size");
      end if;
      if C_Init_Push (P.State.Data (1)'Address, P.Header (1)'Address,
                      Addr (Key)) /= 0
      then
         Fail ("secretstream init push failed");
      end if;
      return P;
   end Init_Push;

   function Push
     (State      : in out Stream_State;
      Message    : Crypto.Byte_Array;
      Additional : Crypto.Byte_Array;
      Kind       : Tag) return Crypto.Byte_Array
   is
      C     : Crypto.Byte_Array (1 .. ABytes + Message'Length);
      C_Len : aliased ULL := 0;
      Rc    : Interfaces.C.int;
   begin
      Rc := C_Push
        (State.Data (1)'Address, C (1)'Address, C_Len'Address,
         Addr (Message), ULL (Message'Length),
         Addr (Additional), ULL (Additional'Length),
         Interfaces.Unsigned_8 (Tag'Enum_Rep (Kind)));
      if Rc /= 0 then
         Fail ("secretstream push failed");
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Natural (C_Len));
      begin
         Result := C (1 .. Natural (C_Len));
         return Result;
      end;
   end Push;

   function Init_Pull (Header, Key : Crypto.Byte_Array) return Stream_State is
      S : Stream_State;
   begin
      if Header'Length /= Header_Size or else Key'Length /= Key_Size then
         Fail ("header or key size");
      end if;
      if C_Init_Pull (S.Data (1)'Address, Addr (Header), Addr (Key)) /= 0 then
         Fail ("secretstream init pull failed");
      end if;
      return S;
   end Init_Pull;

   function Pull
     (State      : in out Stream_State;
      Ciphertext : Crypto.Byte_Array;
      Additional : Crypto.Byte_Array) return Pulled
   is
      M     : Crypto.Byte_Array (1 .. Ciphertext'Length);
      M_Len : aliased ULL := 0;
      Tag_B : aliased Interfaces.Unsigned_8 := 0;
      Rc    : Interfaces.C.int;
   begin
      if Ciphertext'Length < ABytes then
         Fail ("ciphertext size");
      end if;
      Rc := C_Pull
        (State.Data (1)'Address, M (1)'Address, M_Len'Address, Tag_B'Address,
         Addr (Ciphertext), ULL (Ciphertext'Length),
         Addr (Additional), ULL (Additional'Length));
      if Rc /= 0 then
         Fail ("secretstream pull failed");
      end if;
      declare
         Result : Pulled (Natural (M_Len));
      begin
         Result.Message := M (1 .. Natural (M_Len));
         Result.Kind := Tag'Enum_Val (Natural (Tag_B));
         return Result;
      end;
   end Pull;

end Crypto.Secretstream;
