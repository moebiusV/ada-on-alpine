# libsodium-ada

A complete, thin Ada 2022 binding to [libsodium](https://doc.libsodium.org/).
Every public primitive is mapped onto an idiomatic Ada package: fixed-size
buffers are `Crypto.Byte_Array` slices, error returns become exceptions, and
opaque C state is hidden behind private types. No raw pointers escape.

The root package `Crypto` holds the core utilities and primitives; the
higher-level suites are child packages:

| Package | Primitive(s) |
|---|---|
| `Crypto` | init/version, random bytes, SHA-256/512, HMAC, base-64/hex, constant-time compare, big-number helpers, `memzero`, ChaCha20-Poly1305 AEAD, pad/unpad, `runtime_has_*`, misuse handler, `Secure_Buffer` (`sodium_malloc`/`mlock`/`mprotect`) |
| `Crypto.Sign` | Ed25519 signatures (detached/attached/streaming, key conversion) |
| `Crypto.Box` | Curve25519-XSalsa20-Poly1305 public-key encryption, sealed boxes |
| `Crypto.Scalarmult` | Curve25519 / Ristretto255 scalar multiplication |
| `Crypto.Kx` | X25519 key exchange |
| `Crypto.Secretbox` | XSalsa20-Poly1305 symmetric authenticated encryption |
| `Crypto.Secretstream` | XChaCha20-Poly1305 encrypted streams with per-message tags |
| `Crypto.Generichash` | BLAKE2b (keyed/unkeyed, one-shot/streaming) |
| `Crypto.Shorthash` | SipHash-2-4 |
| `Crypto.Auth` | HMAC-SHA512-256 |
| `Crypto.Onetimeauth` | Poly1305 one-time authentication |
| `Crypto.Pwhash` | Argon2id/Argon2i and scrypt (raw + encoded-string) |
| `Crypto.Stream` | XSalsa20 / XChaCha20 / ChaCha20 / Salsa20 |
| `Crypto.Aead` | ChaCha20-Poly1305, XChaCha20-Poly1305, AES-256-GCM |

Call `Crypto.Init` once before use. See `libsodium-ada(3)` for the overview,
and the package specifications themselves (installed with the library) for the
full API.

Packaged for Alpine by the `ada-on-alpine` aports overlay as
`testing/libsodium-ada`.
