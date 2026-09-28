pragma Ada_2022;

--  Imsg: a port of OpenBSD's imsg message-passing protocol (portable
--  imsg.c / imsg-buffer.c) to Ada, so a C peer using the portable imsg.c
--  and an Ada peer using this package interoperate byte-for-byte over a
--  unix-domain socket.
--
--  A frame is a 16-byte header of four 32-bit fields -- type, length,
--  peer ID, PID -- followed by the payload.  Every field is encoded in
--  host byte order (little-endian on the x86-64 targets), exactly as
--  imsg.c writes struct imsg_hdr; a record is never copied across a
--  process boundary by its in-memory representation.
--
--  Length is the TOTAL frame size including the 16-byte header (so a
--  zero-payload frame has length 16).  The high bit (IMSG_FD_Mark) marks
--  a descriptor attached with SCM_RIGHTS, exactly as OpenBSD's imsg does.
--  A malformed frame (short, oversized, or length-mismatched) raises
--  Constraint_Error.

with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Vectors;
with Ada.Streams;
with GNAT.Sockets;
with Interfaces;
with System;

package Imsg is

   type U32 is mod 2 ** 32;

   type Message_Type is new U32;
   type Peer_Id      is new U32;
   type Pid_Type     is new U32;

   Header_Size  : constant := 16;
   Max_Msg_Size : constant := 16_384;             --  MAX_IMSGSIZE in imsg.h
   IMSG_FD_Mark : constant U32 := 16#8000_0000#;  --  fd-attached flag in len

   type Payload is array (Positive range <>) of Ada.Streams.Stream_Element;

   --  Wire and Payload are one byte-array type; Wire denotes the encoded
   --  frame form.
   subtype Wire is Payload;

   --  An ordered list of payload parts, for Compose_V (imsg_composev).
   package Payload_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive, Element_Type => Payload);

   --  A frame's payload is variable length; the discriminant carries the
   --  number of payload bytes (the on-wire length is Header_Size + Length).
   pragma Warnings (Off, "Storage_Error");
   type Frame (Length : Natural := 0) is record
      Kind : Message_Type;
      Peer : Peer_Id;
      Pid  : Pid_Type;
      Data : Payload (1 .. Length);
   end record;
   pragma Warnings (On, "Storage_Error");

   --  Encode a frame to its wire form.
   function Encode (F : Frame) return Wire;

   --  Decode a wire form into a frame.  Raises Constraint_Error on a
   --  malformed frame.
   function Decode (B : Wire) return Frame;

   --  Transport: send one frame's wire form, or read one frame, over a
   --  connected socket.  Send_Frame writes every byte; Recv_Frame reads a
   --  full frame (header + payload) and raises Transport_Error on a clean
   --  end-of-stream or a socket failure, and Constraint_Error on a
   --  malformed frame.
   Transport_Error : exception;

   --  A received frame: the encoded wire form plus the descriptor it
   --  carried (-1 when none), mirroring OpenBSD's struct imsg (.fd).
   pragma Warnings (Off, "Storage_Error");
   type Received (Length : Natural := 0) is record
      Fd   : Integer := -1;
      Data : Payload (1 .. Length);
   end record;
   pragma Warnings (On, "Storage_Error");

   --  Send one frame.  When Fd /= -1 the descriptor is attached via
   --  SCM_RIGHTS and the IMSG_FD_Mark bit is set in the header -- the
   --  analogue of imsg_compose(..., fd, ...).  The peer receives a
   --  duplicate; the caller keeps ownership of Fd.
   procedure Send_Frame
     (Sock : GNAT.Sockets.Socket_Type; B : Wire; Fd : Integer := -1);

   --  Receive one frame and any attached descriptor (Fd = -1 when the frame
   --  carried none) -- the analogue of imsg_get()'s struct imsg.fd.  The
   --  caller owns the received descriptor and must close it.
   function Recv_Frame (Sock : GNAT.Sockets.Socket_Type) return Received;

   --  High-level descriptor handoff: transfer a descriptor to the peer over
   --  Sock, attached to frame B, and then close the caller's copy (the peer
   --  receives the kernel-installed duplicate).  Fd is closed here even when
   --  the send raises, so handing a descriptor over never leaks the caller's
   --  copy.  Use this instead of Send_Frame (Sock, B, To_C (Fd)) when the
   --  descriptor is being given away, not shared.
   procedure Send_Fd
     (Sock : GNAT.Sockets.Socket_Type;
      B    : Wire;
      Fd   : GNAT.Sockets.Socket_Type);

   ---------------------------------------------------------------
   --  Buffer: a growable byte buffer (the C ibuf)               --
   ---------------------------------------------------------------
   --  A byte buffer with a read cursor and a write cursor, an optional
   --  attached descriptor (SCM_RIGHTS), and typed little-/big-endian
   --  get/put.  Used to compose a message before queueing it on a Connection,
   --  and to pull typed fields out of a received message.

   type Buffer is limited private;
   type Buffer_Access is access Buffer;

   procedure Open_Buffer (B : out Buffer; Len : Natural := 0);
   procedure Dynamic_Buffer (B : out Buffer; Len, Max : Natural);

   procedure Add (B : in out Buffer; Data : Payload);
   procedure Add_U8 (B : in out Buffer; V : Interfaces.Unsigned_8);
   procedure Add_U16_LE (B : in out Buffer; V : Interfaces.Unsigned_16);
   procedure Add_U32_LE (B : in out Buffer; V : Interfaces.Unsigned_32);
   procedure Add_U64_LE (B : in out Buffer; V : Interfaces.Unsigned_64);
   procedure Add_U16_BE (B : in out Buffer; V : Interfaces.Unsigned_16);
   procedure Add_U32_BE (B : in out Buffer; V : Interfaces.Unsigned_32);
   procedure Add_U64_BE (B : in out Buffer; V : Interfaces.Unsigned_64);
   procedure Add_Zero (B : in out Buffer; Len : Natural);
   --  Append S's bytes verbatim (no terminator or padding).
   procedure Add_String (B : in out Buffer; S : String);
   --  Append From's unread bytes (ibuf_add_ibuf).
   procedure Add_Ibuf (B : in out Buffer; From : Buffer);
   --  Append S into exactly Len bytes, NUL-terminating and zero-padding the
   --  rest (ibuf_add_strbuf).  Raises Constraint_Error if S'Length >= Len.
   procedure Add_Strbuf (B : in out Buffer; S : String; Len : Natural);

   procedure Reserve
     (B : in out Buffer; Len : Natural; Ptr : out System.Address);

   --  The bytes still unread (Rpos + 1 .. Wpos), as a copy (ibuf_data/size).
   function Data (B : Buffer) return Payload;
   function Size (B : Buffer) return Natural;
   function Left (B : Buffer) return Natural;
   procedure Truncate (B : in out Buffer; Len : Natural);
   procedure Rewind (B : in out Buffer);

   --  Overwrite bytes already written: Pos is the 0-indexed offset from the
   --  read cursor (ibuf_set / ibuf_seek write at rpos + pos).  Close uses
   --  Pos = 4 to write the header's length field.
   procedure Set_Bytes (B : in out Buffer; Pos : Natural; Data : Payload);
   procedure Set_U8
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_8);
   procedure Set_U16_LE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_16);
   procedure Set_U16_BE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_16);
   procedure Set_U32_LE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_32);
   procedure Set_U32_BE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_32);
   procedure Set_U64_LE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_64);
   procedure Set_U64_BE
     (B : in out Buffer; Pos : Natural; V : Interfaces.Unsigned_64);
   procedure Set_Max_Size (B : in out Buffer; Max : Natural);

   procedure Get (B : in out Buffer; Data : out Payload);
   procedure Get_U8 (B : in out Buffer; V : out Interfaces.Unsigned_8);
   procedure Get_U16_LE (B : in out Buffer; V : out Interfaces.Unsigned_16);
   procedure Get_U32_LE (B : in out Buffer; V : out Interfaces.Unsigned_32);
   procedure Get_U64_LE (B : in out Buffer; V : out Interfaces.Unsigned_64);
   procedure Get_U16_BE (B : in out Buffer; V : out Interfaces.Unsigned_16);
   procedure Get_U32_BE (B : in out Buffer; V : out Interfaces.Unsigned_32);
   procedure Get_U64_BE (B : in out Buffer; V : out Interfaces.Unsigned_64);
   procedure Get_String (B : in out Buffer; S : out String);
   procedure Skip (B : in out Buffer; Len : Natural);

   --  Wrap an existing byte string as a buffer for reading (ibuf_from_buffer).
   --  Unlike the C zero-copy view, this copies so the buffer owns its data.
   procedure From_Buffer (B : out Buffer; Data : Payload);
   --  As From_Buffer, but from another buffer's unread bytes (ibuf_from_ibuf).
   procedure From_Ibuf (B : out Buffer; From : Buffer);
   --  Extract Len unread bytes into a fresh buffer and advance the read cursor
   --  (ibuf_get_ibuf).  Raises Constraint_Error if fewer than Len remain.
   procedure Get_Ibuf (B : in out Buffer; Len : Natural; New_B : out Buffer);

   procedure Attach_Fd (B : in out Buffer; Fd : Integer);
   function Take_Fd (B : in out Buffer) return Integer;
   function Has_Fd (B : Buffer) return Boolean;

   procedure Free (B : in out Buffer);

   ---------------------------------------------------------------
   --  Connection: a buffered imsg channel (the C imsgbuf)       --
   ---------------------------------------------------------------
   --  Wraps a connected socket with a write queue and a read buffer.  Compose
   --  queues a message; Write/Flush drain the queue to the socket; Read blocks
   --  for data, buffers it, and splits it into complete messages; Get returns
   --  the next complete message.  The socket must be blocking (as for the
   --  low-level Send_Frame/Recv_Frame).  Read raises Connection_Closed on a
   --  clean end-of-stream, after which the caller should drain any messages
   --  Read already queued; Get raises Not_Complete when none is ready.

   type Connection is limited private;

   Not_Complete      : exception;  -- Get: no complete message is ready yet
   Connection_Closed : exception;  -- Read: the peer closed the channel

   procedure Initialize
     (C : out Connection; Sock : GNAT.Sockets.Socket_Type);
   procedure Allow_Fd_Pass (C : in out Connection);
   procedure Set_Max_Size (C : in out Connection; Max : Natural);

   procedure Read (C : in out Connection);
   procedure Write (C : in out Connection);
   procedure Flush (C : in out Connection);
   procedure Clear (C : in out Connection);

   function Queue_Length (C : Connection) return Natural;
   function Get (C : in out Connection) return Received;

   procedure Compose
     (C    : in out Connection;
      Kind : Message_Type;
      Peer : Peer_Id := 0;
      Pid  : Pid_Type := 0;
      Fd   : Integer  := -1;
      Data : Payload  := [1 .. 0 => 0]);

   --  Begin composing a message of Data_Length bytes, returning the buffer so
   --  the caller can Add typed fields before Close.  (imsg_create / imsg_add /
   --  imsg_close, folded into one idiomatic flow.)
   function Compose_Buffer
     (C           : in out Connection;
      Kind        : Message_Type;
      Data_Length : Natural;
      Peer        : Peer_Id := 0;
      Pid         : Pid_Type := 0) return Buffer_Access;
   procedure Close (C : in out Connection; Msg : in out Buffer_Access);

   --  Forward a received message to C, closing any attached descriptor
   --  (imsg_forward).  The frame is re-encoded with its original type, peer,
   --  pid and payload.
   procedure Forward (C : in out Connection; Msg : Received);

   --  Compose from several non-contiguous parts (imsg_composev).
   procedure Compose_V
     (C     : in out Connection;
      Kind  : Message_Type;
      Peer  : Peer_Id := 0;
      Pid   : Pid_Type := 0;
      Fd    : Integer  := -1;
      Parts : Payload_Vectors.Vector);

   --  Attach an opaque value to the connection (imsgbuf_set/get_userdata).
   procedure Set_Userdata (C : in out Connection; Ptr : System.Address);
   function Get_Userdata (C : Connection) return System.Address;

   --  Callback invoked with Userdata after each message is queued by Close
   --  (imsgbuf_set_close_callback).
   type Close_Callback is access procedure (Userdata : System.Address);
   procedure Set_Close_Callback (C : in out Connection; Cb : Close_Callback);

private

   type Payload_Access is access Payload;

   type Buffer is record
      Data : Payload_Access := null;
      Cap  : Natural := 0;      --  allocated bytes
      Wpos : Natural := 0;      --  write cursor
      Rpos : Natural := 0;      --  read cursor
      Max  : Natural := 0;      --  max size (0 = unlimited)
      Fd   : Integer := -1;     --  attached descriptor
   end record;

   package Buffer_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Buffer_Access);

   Read_Size : constant := 65_535;

   type Connection is record
      Sock     : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Write_Q  : Buffer_Vectors.Vector;   --  messages pending flush
      Read_Buf : Payload_Access := null;
      Read_Len : Natural := 0;            --  bytes held in Read_Buf
      Pending  : Buffer_Access := null;   --  message being assembled
      Read_Q   : Buffer_Vectors.Vector;   --  complete messages pending get
      Allow_Fd : Boolean := False;
      Max_Size : Natural := Max_Msg_Size;
      Pid      : Natural := 0;
      Userdata : System.Address := System.Null_Address;
      Cb       : Close_Callback := null;
   end record;

end Imsg;
