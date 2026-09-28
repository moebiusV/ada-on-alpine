pragma Ada_2022;

with Crypto.Raw;


--  Ed25519 signatures (crypto_sign_*): key generation, detached and attached
--  signing, and verification.  A detached signature is Signature_Size bytes; an
--  attached (combined) signature is the signature prepended to the message.
--  The stateful form (New_State / Update / Final_Create / Final_Verify) signs
--  a message streaming in chunks (the ed25519ph pre-hashed variant).
package Crypto.Sign is

   Signature_Size  : constant := 64;   --  crypto_sign_BYTES
   Seed_Size       : constant := 32;
   Public_Key_Size : constant := 32;
   Secret_Key_Size : constant := 64;
   State_Size      : constant := Crypto.Raw.Sign_Statebytes;

   type Keypair is record
      Public : Crypto.Byte_Array (1 .. Public_Key_Size);
      Secret : Crypto.Byte_Array (1 .. Secret_Key_Size);
   end record;

   subtype Sign_State is Crypto.State_Buffer (State_Size);

   --  Fresh random keypair.
   function Keygen return Keypair;

   --  Keypair derived from a Seed_Size-byte seed (deterministic).
   function Seed_Keypair (Seed : Crypto.Byte_Array) return Keypair;

   --  Detached sign / verify.  Sign returns the Signature_Size-byte signature;
   --  Verify returns False (rather than raising) on a bad signature.
   function Sign
     (Message    : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Verify
     (Signature, Message, Public_Key : Crypto.Byte_Array) return Boolean;

   --  Attached (combined) sign / open.  Open_Attached raises Crypto_Error on
   --  a failed verification and returns the recovered message otherwise.
   function Sign_Attached
     (Message    : Crypto.Byte_Array;
      Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Open_Attached
     (Signed     : Crypto.Byte_Array;
      Public_Key : Crypto.Byte_Array) return Crypto.Byte_Array;

   --  Extract the public key / seed from a secret key.
   function Secret_To_Public (Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Secret_To_Seed (Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array;

   --  Ed25519 <-> X25519 key conversion (32-byte results).
   function Public_To_Curve25519 (Public_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array;
   function Secret_To_Curve25519 (Secret_Key : Crypto.Byte_Array)
      return Crypto.Byte_Array;

   --  Streaming signer: feed chunks with Update, then Final_Create to sign or
   --  Final_Verify to verify.  New_State resets a state.
   function New_State return Sign_State;
   procedure Update (State : in out Sign_State; Chunk : Crypto.Byte_Array);
   function Final_Create
     (State      : Sign_State;
      Secret_Key : Crypto.Byte_Array) return Crypto.Byte_Array;
   function Final_Verify
     (State      : Sign_State;
      Signature, Public_Key : Crypto.Byte_Array) return Boolean;

end Crypto.Sign;
