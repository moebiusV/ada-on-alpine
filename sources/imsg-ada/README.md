# imsg-ada

A port of OpenBSD's `imsg` message-passing protocol (the portable `imsg.c` /
`imsg-buffer.c` wire format) to Ada, so a C peer using the portable `imsg.c`
and an Ada peer using this package interoperate byte-for-byte over a
unix-domain socket.

## Introduction

`Imsg` is a direct Ada rendering of OpenBSD's portable `imsg.c` /
`imsg-buffer.c`, so a C programmer can read it the same way.  Each `struct`
becomes an Ada type you hold by value, and each function that took a pointer to
that struct takes it as an `in` / `in out` parameter:

- `struct imsgbuf *` → a `Connection` (the buffered channel);
- `struct ibuf *` → a `Buffer` (the growable byte buffer);
- `imsg_compose(ibuf, type, peerid, pid, fd, data, datalen)` →
  `Connection.Compose (C, Kind, Peer, Pid, Fd, Data)`;
- `imsg_get(ibuf, &imsg)`, which filled a caller-owned `struct imsg`, becomes
  `Connection.Get (C)` returning an owned `Received` — the message is a value
  you own, with nothing to `imsg_free`.

The safety comes from what that translation changes.  Error returns become
exceptions: `-1` + `errno` is an `Imsg.Transport_Error`, and a malformed frame
is `Constraint_Error` — there is no `errno` to read and no `-1` to miss.
Because `Get` returns an owned `Received`, a message is a value you release by
going out of scope, never a `struct imsg` you must remember to `imsg_free`.
The header's `type`, `peerid` and `pid` are distinct `mod 2**32` types —
`Message_Type`, `Peer_Id` and `Pid_Type` — so a peer id can't be passed where a
message type is expected.  `Send_Fd` hands a descriptor over safely by closing
the caller's copy even when the send raises, so a handed-over descriptor never
leaks.  And the `ibuf_add_n*`/`ibuf_get_n*` family becomes named, checked
accessors — `Add_U32_LE`, `Get_U64_BE` — instead of positional endian calls you
must keep straight.

There are three layers, each a faithful rendering of the C:

1. **Codec** — `Encode` / `Decode` turn a `Frame` into its on-wire bytes and
   back, so a message is never copied across a process boundary by its
   in-memory representation.
2. **Buffer** (`ibuf`) — a growable byte buffer with typed little-/big-endian
   `Add`/`Get`/`Set` accessors, for composing and parsing messages.
3. **Connection** (`imsgbuf`) — a buffered channel over a connected socket,
   with `Compose` / `Compose_Buffer` / `Flush` to send and `Read` / `Get` to
   receive, including `SCM_RIGHTS` descriptor passing.

## Quickstart

Install the package (Alpine: `apk add imsg-ada`), then `with "imsg";` from a GNAT
project file. It is pure Ada on the GNAT runtime — no C dependencies.

```ada
-- hello.adb
pragma Ada_2022;
with Ada.Text_IO;
with GNAT.Sockets;
with Imsg;

procedure Hello is
   A, B : GNAT.Sockets.Socket_Type;
   Ca   : Imsg.Connection;
   Cb   : Imsg.Connection;
begin
   GNAT.Sockets.Create_Socket_Pair (A, B);
   Imsg.Initialize (Ca, A);
   Imsg.Initialize (Cb, B);

   Imsg.Compose (Ca, 1, 0, 0, -1, [16#68#, 16#69#]);   --  kind 1, "hi"
   Imsg.Flush (Ca);

   Imsg.Read (Cb);
   declare
      R : constant Imsg.Received := Imsg.Get (Cb);
      F : constant Imsg.Frame := Imsg.Decode (R.Data);
   begin
      Ada.Text_IO.Put_Line
        ("kind=" & Imsg.Message_Type'Image (F.Kind)
         & " payload=" & Natural'Image (F.Data'Length) & " bytes");
   end;
end Hello;
```

```gpr
-- hello.gpr
with "imsg";
project Hello is
   for Source_Dirs use (".");
   for Object_Dir use "obj";
   for Exec_Dir use ".";
   for Main use ("hello.adb");
end Hello;
```

```sh
GPR_PROJECT_PATH=/usr/share/gpr gprbuild -P hello.gpr -p
./hello
```

## Mapping from C

If you know OpenBSD's `imsg.c` / `imsg-buffer.c`, the mapping is one-to-one:

| OpenBSD C | Ada |
|---|---|
| `imsg_compose(ibuf, type, peerid, pid, fd, data, datalen)` | `Connection.Compose (C, Kind, Peer, Pid, Fd, Data)` |
| `imsg_composev(ibuf, ...)` | `Connection.Compose_V (C, Kind, Peer, Pid, Fd, Parts)` |
| `imsg_create` + `imsg_add` + `imsg_close` | `Connection.Compose_Buffer (C, Kind, Len, ...)` + `Buffer.Add_*` + `Connection.Close` |
| `imsg_flush(ibuf)` | `Connection.Flush (C)` |
| `imsg_read(ibuf)` | `Connection.Read (C)` |
| `imsg_get(ibuf, &imsg)` | `Connection.Get (C)` → `Received` (`.Data`, `.Fd`) |
| `ibuf_add(buf, data, len)` | `Buffer.Add (B, Data)` |
| `ibuf_add_n32(buf, v)` | `Buffer.Add_U32_LE (B, V)` |
| `ibuf_get_n32(buf)` | `Buffer.Get_U32_LE (B)` |
| `ibuf_open` / `ibuf_dynamic` | `Buffer.Open_Buffer` / `Buffer.Dynamic_Buffer` |

## Examples

The [`examples/imsg_example.adb`](examples/imsg_example.adb) program walks
through the codec and a socketpair connection:

```sh
cd examples
GPR_PROJECT_PATH=/usr/share/gpr gprbuild -P examples.gpr -p
./imsg_example
```

## Wire format

A frame is a 16-byte header of four 32-bit little-endian (host-order) fields
followed by the payload:

```
offset  size  field
0       4     type    (message type)
4       4     len     (TOTAL frame size incl. header; bit 31 = fd attached)
8       4     peerid  (origin peer id)
12      4     pid     (origin process id)
16      ..    payload
```

`len` includes the 16-byte header (a zero-payload frame has `len == 16`).
The high bit of `len` (`IMSG_FD_Mark == 16#8000_0000#`) marks a `SCM_RIGHTS`
descriptor attached with `sendmsg`/`recvmsg`, exactly as OpenBSD's imsg does.

## API

- `Imsg.Encode` / `Imsg.Decode` — frame <-> wire codec.
- `Imsg.Send_Frame (Sock, B, Fd := -1)` — write one frame; `Fd /= -1`
  attaches a descriptor via `SCM_RIGHTS` (the analogue of
  `imsg_compose(..., fd, ...)`).
- `Imsg.Recv_Frame (Sock)` returns `Imsg.Received` (`.Data` + `.Fd`) — the
  analogue of `imsg_get()`'s `struct imsg` (`.fd`, `-1` when none).
- `Imsg.Send_Fd` — transfer a descriptor to the peer, closing the caller's copy
  even on failure.
- `Imsg.Buffer` — the growable `ibuf`, with `Add_U*_LE/BE`, `Get_U*_LE/BE`,
  `Set_*`, `Data`, `Size`, `Left`, `Attach_Fd`/`Take_Fd`.
- `Imsg.Connection` — the buffered `imsgbuf`: `Initialize`, `Compose`,
  `Compose_Buffer`/`Close`, `Compose_V`, `Flush`, `Read`, `Get`, `Forward`,
  `Queue_Length`.

Malformed frames raise `Constraint_Error`; a clean end-of-stream or socket
failure raises `Imsg.Transport_Error`.

## License

ISC.
