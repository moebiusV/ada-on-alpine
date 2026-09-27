pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Sign is

   use type Interfaces.C.int;

   --  64-bit unsigned, matching libsodium's unsigned long long lengths.
   type ULL is mod 2 ** 64;
   pragma Convention (C, ULL);

   function Addr (B : Crypto.Byte_Array) return System.Address is
   begin
      if B'Length = 0 then
         return System.Null_Address;
      end if;
      return B (B'First)'Address;
   end Addr;

   function C_Keypair (Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_keypair";

   function C_Seed_Keypair
     (Pk, Sk, Seed : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_seed_keypair";

   function C_Detached
     (Sig : System.Address; Sig_Len : System.Address;
      M   : System.Address; M_Len   : ULL;
      Sk  : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_detached";

   function C_Verify_Detached
     (Sig, M : System.Address; M_Len : ULL; Pk : System.Address)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_verify_detached";

   function C_Sign
     (Sm : System.Address; Sm_Len : System.Address;
      M  : System.Address; M_Len  : ULL;
      Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign";

   function C_Open
     (M : System.Address; M_Len : System.Address;
      Sm : System.Address; Sm_Len : ULL;
      Pk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_open";

   function C_Sk_To_Pk (Pk, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_ed25519_sk_to_pk";

   function C_Sk_To_Seed (Seed, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_sign_ed25519_sk_to_seed";

   function C_Pk_To_Curve25519
     (Ck, Pk : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_sign_ed25519_pk_to_curve25519";

   function C_Sk_To_Curve25519
     (Ck, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "crypto_sign_ed25519_sk_to_curve25519";

   function C_Init (State : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_init";

   function C_Update
     (State, M : System.Address; M_Len : ULL) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_update";

   function C_Final_Create
     (State, Sig, Sig_Len, Sk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_final_create";

   function C_Final_Verify
     (State, Sig, Pk : System.Address) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_sign_final_verify";

   Curve25519_Size : constant := 32;

   function Keygen return Keypair is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size);
      Sk : Crypto.Byte_Array (1 .. Secret_Key_Size);
      Rc : Interfaces.C.int;
   begin
      Rc := C_Keypair (Pk (1)'Address, Sk (1)'Address);
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sign keygen failed";
      end if;
      return (Public => Pk, Secret => Sk);
   end Keygen;

   function Seed_Keypair (Seed : Crypto.Byte_Array) return Keypair is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size);
      Sk : Crypto.Byte_Array (1 .. Secret_Key_Size);
      Rc : Interfaces.C.int;
   begin
      if Seed'Length /= Seed_Size then
         raise Crypto.Crypto_Error with "seed size";
      end if;
      Rc := C_Seed_Keypair (Pk (1)'Address, Sk (1)'Address, Addr (Seed));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sign seed keypair failed";
      end if;
      return (Public => Pk, Secret => Sk);
   end Seed_Keypair;

   function Sign
     (Message    : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array
   is
      Sig     : Crypto.Byte_Array (1 .. Signature_Size);
      Sig_Len : aliased ULL := 0;
      Rc      : Interfaces.C.int;
   begin
      if Secret_Key'Length /= Secret_Key_Size then
         raise Crypto.Crypto_Error with "secret key size";
      end if;
      Rc := C_Detached
        (Sig (1)'Address, Sig_Len'Address,
         Addr (Message), ULL (Message'Length), Addr (Secret_Key));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sign failed";
      end if;
      return Sig;
   end Sign;

   function Verify
     (Signature, Message, Public_Key : Crypto.Byte_Array) return Boolean
   is
   begin
      if Signature'Length /= Signature_Size
        or else Public_Key'Length /= Public_Key_Size
      then
         return False;
      end if;
      return C_Verify_Detached
        (Addr (Signature), Addr (Message), ULL (Message'Length),
         Addr (Public_Key)) = 0;
   end Verify;

   function Sign_Attached
     (Message    : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array
   is
      Sm     : Crypto.Byte_Array (1 .. Signature_Size + Message'Length);
      Sm_Len : aliased ULL := 0;
      Rc     : Interfaces.C.int;
   begin
      if Secret_Key'Length /= Secret_Key_Size then
         raise Crypto.Crypto_Error with "secret key size";
      end if;
      Rc := C_Sign
        (Sm (1)'Address, Sm_Len'Address,
         Addr (Message), ULL (Message'Length), Addr (Secret_Key));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sign failed";
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Natural (Sm_Len));
      begin
         Result := Sm (1 .. Natural (Sm_Len));
         return Result;
      end;
   end Sign_Attached;

   function Open_Attached
     (Signed     : Crypto.Byte_Array;
      Public_Key : Crypto.Byte_Array) return Crypto.Byte_Array
   is
      Msg     : Crypto.Byte_Array (1 .. Signed'Length);
      Msg_Len : aliased ULL := 0;
      Rc      : Interfaces.C.int;
   begin
      if Public_Key'Length /= Public_Key_Size then
         raise Crypto.Crypto_Error with "public key size";
      end if;
      if Signed'Length < Signature_Size then
         raise Crypto.Crypto_Error with "signed message too short";
      end if;
      Rc := C_Open
        (Msg (1)'Address, Msg_Len'Address,
         Addr (Signed), ULL (Signed'Length), Addr (Public_Key));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "signature verification failed";
      end if;
      declare
         Result : Crypto.Byte_Array (1 .. Natural (Msg_Len));
      begin
         Result := Msg (1 .. Natural (Msg_Len));
         return Result;
      end;
   end Open_Attached;

   function Secret_To_Public (Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Pk : Crypto.Byte_Array (1 .. Public_Key_Size);
      Rc : Interfaces.C.int;
   begin
      if Secret_Key'Length /= Secret_Key_Size then
         raise Crypto.Crypto_Error with "secret key size";
      end if;
      Rc := C_Sk_To_Pk (Pk (1)'Address, Addr (Secret_Key));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sk_to_pk failed";
      end if;
      return Pk;
   end Secret_To_Public;

   function Secret_To_Seed (Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Seed : Crypto.Byte_Array (1 .. Seed_Size);
      Rc   : Interfaces.C.int;
   begin
      if Secret_Key'Length /= Secret_Key_Size then
         raise Crypto.Crypto_Error with "secret key size";
      end if;
      Rc := C_Sk_To_Seed (Seed (1)'Address, Addr (Secret_Key));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sk_to_seed failed";
      end if;
      return Seed;
   end Secret_To_Seed;

   function Public_To_Curve25519 (Public_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Ck : Crypto.Byte_Array (1 .. Curve25519_Size);
      Rc : Interfaces.C.int;
   begin
      if Public_Key'Length /= Public_Key_Size then
         raise Crypto.Crypto_Error with "public key size";
      end if;
      Rc := C_Pk_To_Curve25519 (Ck (1)'Address, Addr (Public_Key));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "pk_to_curve25519 failed";
      end if;
      return Ck;
   end Public_To_Curve25519;

   function Secret_To_Curve25519 (Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array
   is
      Ck : Crypto.Byte_Array (1 .. Curve25519_Size);
      Rc : Interfaces.C.int;
   begin
      if Secret_Key'Length /= Secret_Key_Size then
         raise Crypto.Crypto_Error with "secret key size";
      end if;
      Rc := C_Sk_To_Curve25519 (Ck (1)'Address, Addr (Secret_Key));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sk_to_curve25519 failed";
      end if;
      return Ck;
   end Secret_To_Curve25519;

   function New_State return Sign_State is
      S  : Sign_State;
      Rc : Interfaces.C.int;
   begin
      Rc := C_Init (S.Data (1)'Address);
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sign init failed";
      end if;
      return S;
   end New_State;

   procedure Update (State : in out Sign_State; Chunk : Crypto.Byte_Array) is
      Rc : Interfaces.C.int;
   begin
      Rc := C_Update
        (State.Data (1)'Address, Addr (Chunk), ULL (Chunk'Length));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sign update failed";
      end if;
   end Update;

   function Final_Create
     (State      : Sign_State;
      Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array
   is
      Sig     : Crypto.Byte_Array (1 .. Signature_Size);
      Sig_Len : aliased ULL := 0;
      Rc      : Interfaces.C.int;
   begin
      if Secret_Key'Length /= Secret_Key_Size then
         raise Crypto.Crypto_Error with "secret key size";
      end if;
      Rc := C_Final_Create
        (State.Data (1)'Address, Sig (1)'Address, Sig_Len'Address,
         Addr (Secret_Key));
      if Rc /= 0 then
         raise Crypto.Crypto_Error with "sign final failed";
      end if;
      return Sig;
   end Final_Create;

   function Final_Verify
     (State      : Sign_State;
      Signature, Public_Key : Crypto.Byte_Array) return Boolean
   is
   begin
      if Signature'Length /= Signature_Size
        or else Public_Key'Length /= Public_Key_Size
      then
         return False;
      end if;
      return C_Final_Verify
        (State.Data (1)'Address, Addr (Signature), Addr (Public_Key)) = 0;
   end Final_Verify;

end Crypto.Sign;
