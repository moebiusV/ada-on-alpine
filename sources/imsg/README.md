# imsg

A port of OpenBSD's `imsg` message-passing protocol (the portable `imsg.c` /
`imsg-buffer.c` wire format) to Ada, so a C peer using the portable `imsg.c`
and an Ada peer using this package interoperate byte-for-byte over a
unix-domain socket.

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

Malformed frames raise `Constraint_Error`; a clean end-of-stream or socket
failure raises `Imsg.Transport_Error`.

## License

ISC.
