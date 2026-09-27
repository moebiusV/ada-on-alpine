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

with Ada.Streams;
with GNAT.Sockets;

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

end Imsg;
