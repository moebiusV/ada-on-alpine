/* Compose one imsg frame the way portable imsg.c's imsg_compose does -- a
 * 16-byte host-order header (type, len, peerid, pid) followed by the payload --
 * and write the exact wire bytes to stdout.  c_interop decodes them, proving
 * the Ada codec agrees with imsg.c byte-for-byte. */
#include <stdint.h>
#include <stdio.h>

struct imsg_hdr {
	uint32_t type;
	uint32_t len;
	uint32_t peerid;
	uint32_t pid;
};

int main(void)
{
	static const unsigned char payload[] = { 0xAA, 0xBB, 0xCC };
	struct imsg_hdr hdr;

	hdr.type   = 0x01020304u;
	hdr.len    = (uint32_t)(sizeof hdr + sizeof payload);
	hdr.peerid = 0x05u;
	hdr.pid    = 0x06u;

	fwrite(&hdr, sizeof hdr, 1, stdout);
	fwrite(payload, sizeof payload, 1, stdout);
	return 0;
}
