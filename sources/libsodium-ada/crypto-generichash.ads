pragma Ada_2022;


--  BLAKE2b (crypto_generichash_*): a keyed or unkeyed hash of configurable
--  output length, with one-shot and streaming forms.
package Crypto.Generichash is

   Bytes        : constant := 32;   --  default output length
   Bytes_Min    : constant := 16;
   Bytes_Max    : constant := 64;
   Key_Size     : constant := 32;
   Key_Size_Min : constant := 16;
   Key_Size_Max : constant := 64;
   State_Size   : constant := 384;

   type Stream_State is record
      State  : Crypto.State_Buffer (State_Size);
      Length : Natural := 0;
   end record;

   --  One-shot.  Length must be within Bytes_Min .. Bytes_Max.
   function Hash (Data : Crypto.Byte_Array; Length : Natural := Bytes)
      return Crypto.Byte_Array;
   function Hash_Keyed
     (Data, Key : Crypto.Byte_Array; Length : Natural := Bytes)
      return Crypto.Byte_Array;

   --  Streaming: feed chunks with Update, then Final.
   function New_State (Length : Natural := Bytes) return Stream_State;
   function New_State_Keyed
     (Key : Crypto.Byte_Array; Length : Natural := Bytes) return Stream_State;
   procedure Update (State : in out Stream_State; Chunk : Crypto.Byte_Array);
   function Final (State : Stream_State) return Crypto.Byte_Array;

end Crypto.Generichash;
