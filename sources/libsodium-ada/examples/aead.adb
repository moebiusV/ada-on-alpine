pragma Ada_2022;

with Ada.Streams;
with Ada.Text_IO;
with Crypto;

--  Authenticated encryption: ChaCha20-Poly1305.  Seal encrypts and tags the
--  message; Open decrypts and verifies it, raising Crypto_Error on tampering.
--  Both the detached form (separate tag) and the combined form (ciphertext ||
--  tag in one buffer) are shown.
procedure Aead is

   use type Crypto.Byte_Array;

   function Bytes (S : String) return Crypto.Byte_Array is
      R : Crypto.Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) :=
           Ada.Streams.Stream_Element (Character'Pos (S (I)));
      end loop;
      return R;
   end Bytes;

begin
   Crypto.Init;

   --  Detached mode: ciphertext and tag are separate (Crypto.Sealed_Text).
   declare
      Key    : constant Crypto.Byte_Array := Crypto.Random (Crypto.Key_Size);
      Nonce  : constant Crypto.Byte_Array := Crypto.Random (Crypto.Nonce_Size);
      Aad    : constant Crypto.Byte_Array := Bytes ("from=alice,to=bob");
      Msg    : constant Crypto.Byte_Array := Bytes ("attack at dawn");
      Sealed : constant Crypto.Sealed_Text := Crypto.Seal (Key, Nonce, Aad, Msg);
      Opened : constant Crypto.Byte_Array := Crypto.Open (Key, Nonce, Aad, Sealed);
   begin
      Ada.Text_IO.Put_Line ("detached round-trip: " & Boolean'Image (Opened = Msg));
      Ada.Text_IO.Put_Line ("  ciphertext = " & Crypto.Hex_Encode (Sealed.Ciphertext));
      Ada.Text_IO.Put_Line ("  tag        = " & Crypto.Hex_Encode (Sealed.Tag));
   end;

   --  Combined mode: one buffer, ciphertext || tag.
   declare
      Key   : constant Crypto.Byte_Array := Crypto.Random (Crypto.Key_Size);
      Nonce : constant Crypto.Byte_Array := Crypto.Random (Crypto.Nonce_Size);
      Msg   : constant Crypto.Byte_Array := Bytes ("combined mode");
      C     : constant Crypto.Byte_Array :=
        Crypto.Seal_Combined (Key, Nonce, Bytes (""), Msg);
   begin
      Ada.Text_IO.Put_Line
        ("combined round-trip:  "
         & Boolean'Image (Crypto.Open_Combined (Key, Nonce, Bytes (""), C) = Msg));
   end;
end Aead;
