# libsodium-ada

A thin Ada binding to [libsodium](https://doc.libsodium.org/): cryptographically
random bytes (`randombytes_buf`), HMAC-SHA256 (`crypto_hash_sha256`), and
ChaCha20-Poly1305 AEAD (`crypto_aead_chacha20poly1305_ietf_*`).

The `Crypto` package owns the C object lifetimes and turns C error returns into
Ada results; no raw pointers escape above it. Packaged for Alpine by the
`ada-on-alpine` aports overlay as `testing/libsodium-ada`.
