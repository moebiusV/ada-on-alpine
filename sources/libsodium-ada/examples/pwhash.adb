pragma Ada_2022;

with Ada.Streams;
with Ada.Text_IO;
with Crypto;
with Crypto.Pwhash;

--  Password hashing: Argon2id.  Str_Hash produces a self-describing encoded
--  string (salt and cost embedded) you store; Str_Verify checks a password
--  against it; Str_Needs_Rehash reports whether the stored hash is weaker than
--  a chosen cost preset.
procedure Pwhash is

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

   declare
      Pwd  : constant Crypto.Byte_Array := Bytes ("correct horse battery staple");
      Hash : constant String :=
        Crypto.Pwhash.Str_Hash
          (Pwd, Crypto.Pwhash.Ops_Interactive, Crypto.Pwhash.Mem_Interactive);
   begin
      Ada.Text_IO.Put_Line
        ("verify:     " & Boolean'Image (Crypto.Pwhash.Str_Verify (Hash, Pwd)));
      Ada.Text_IO.Put_Line
        ("wrong pw:   "
         & Boolean'Image (Crypto.Pwhash.Str_Verify (Hash, Bytes ("wrong"))));
      Ada.Text_IO.Put_Line
        ("needs bump: "
         & Boolean'Image
             (Crypto.Pwhash.Str_Needs_Rehash
                (Hash, Crypto.Pwhash.Ops_Moderate, Crypto.Pwhash.Mem_Moderate)));
   end;
end Pwhash;
