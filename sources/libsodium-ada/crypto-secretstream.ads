pragma Ada_2022;


--  Encrypted streams (crypto_secretstream_xchacha20poly1305_*): a sequence of
--  messages authenticated and encrypted under one key, with an explicit tag
--  per message marking plain data, a new key-ratchet, or the stream end.
package Crypto.Secretstream is

   Key_Size    : constant := 32;
   Header_Size : constant := 24;
   ABytes      : constant := 17;   --  ciphertext is message length + ABytes
   State_Size  : constant := 52;

   type Tag is (Message, Push, Rekey, Final);
   for Tag use (Message => 0, Push => 1, Rekey => 2, Final => 3);

   subtype Stream_State is Crypto.State_Buffer (State_Size);

   type Push_Init is record
      State  : Stream_State;
      Header : Crypto.Byte_Array (1 .. Header_Size);
   end record;

   type Pulled (Length : Natural) is record
      Message : Crypto.Byte_Array (1 .. Length);
      Kind    : Tag;
   end record;

   --  Fresh random key.
   function Keygen return Crypto.Byte_Array;

   --  Sender: initialise a push state (the header is sent to the receiver),
   --  then Push each message in order.
   function Init_Push (Key : Crypto.Byte_Array) return Push_Init;
   function Push
     (State      : in out Stream_State;
      Message    : Crypto.Byte_Array;
      Additional : Crypto.Byte_Array;
      Kind       : Tag) return Crypto.Byte_Array;

   --  Receiver: initialise a pull state from the header, then Pull each
   --  ciphertext in order.  Pull raises Crypto_Error on a bad ciphertext.
   function Init_Pull (Header, Key : Crypto.Byte_Array) return Stream_State;
   function Pull
     (State      : in out Stream_State;
      Ciphertext : Crypto.Byte_Array;
      Additional : Crypto.Byte_Array) return Pulled;

end Crypto.Secretstream;
