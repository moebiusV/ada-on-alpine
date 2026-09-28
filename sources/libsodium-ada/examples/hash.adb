pragma Ada_2022;

with Ada.Streams;
with Ada.Text_IO;
with Crypto;
with Crypto.Hash;

--  Hashing: one-shot SHA-256, streaming SHA-256 fed in chunks, and HMAC-SHA256.
procedure Hash is

   use type Crypto.Byte_Array;

   --  String -> Byte_Array (bytes of the string, no terminator).
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
   Crypto.Init;   --  idempotent; call once before any Crypto use

   Ada.Text_IO.Put_Line
     ("sha256(abc) = "
      & Crypto.Hex_Encode (Crypto.Hash_Sha256 (Bytes ("abc"))));

   --  Streaming hash: feed the message in chunks, then finalise.
   declare
      S : Crypto.Hash.Sha256_State := Crypto.Hash.Sha256_Init;
   begin
      Crypto.Hash.Sha256_Update (S, Bytes ("The quick "));
      Crypto.Hash.Sha256_Update (S, Bytes ("brown fox"));
      Ada.Text_IO.Put_Line
        ("sha256(stream) = "
         & Crypto.Hex_Encode (Crypto.Hash.Sha256_Final (S)));
   end;

   Ada.Text_IO.Put_Line
     ("hmac-sha256 = "
      & Crypto.Hex_Encode (Crypto.Hmac_Sha256 (Bytes ("key"), Bytes ("data"))));
end Hash;
