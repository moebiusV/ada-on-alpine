# libsodium-ada

A thin, idiomatic Ada 2022 binding to [libsodium](https://doc.libsodium.org/),
the audited cryptography library. It maps each libsodium primitive onto an
idiomatic Ada package: fixed-size buffers are `Crypto.Byte_Array` slices, error
returns become exceptions (`Crypto.Crypto_Error`), and opaque C state is hidden
behind private types. No raw pointers escape the binding.

## Introduction

The binding is a thin layer that keeps the **C boundary faithful** and the
**Ada side safe**.  If you know libsodium, the mapping is mechanical.

A C call has three parts — an **output buffer**, the **input**, and an `int`
return code you must check:

```c
unsigned char hash[crypto_hash_sha256_BYTES];
crypto_hash_sha256(hash, data, data_len);
```

Ada collapses those three parts into a single return value and an exception:

```ada
Digest : constant Crypto.Byte_Array := Crypto.Hash_Sha256 (Data);
```

Every family follows the same rule: `crypto_<family>_<op>` becomes the child
package `Crypto.<Family>`; the `unsigned char *out` + length parameters become
the function's **return value**; and the `int` status code becomes either a
**`Crypto_Error` exception** (on failure) or a **`Boolean`** (for the `Verify`
predicates).  Inputs stay `Byte_Array`, and the magic `crypto_*_*BYTES`
constants become named size constants (`Crypto.Hash256_Size`,
`Crypto.Secretbox.Nonce_Size`, …).

That translation is what makes the Ada side safe.  Because a failure raises
rather than returning an `int`, there is no `if (crypto_...() != 0) goto fail;`
chain to forget, and the `Verify` predicates are the ones that return `Boolean`
(`False`, never a `-1`).  Because sizes are checked at the call, a wrong-length
key or nonce raises `Crypto_Error` immediately instead of reading the wrong
`*_KEYBYTES` constant and slicing past the end.  The C library's
`crypto_*_state` blocks become private `State_Buffer`s sized from the
ABI-stable `crypto_*_statebytes()`, so you never hand-maintain a magic
`unsigned char[384]`.  Guarded secrets are a `Secure_Buffer` that pins its own
`mlock`ed memory and wipes it on free — no bare `sodium_malloc`/`sodium_free`
pair to get wrong.  Detached and combined modes are siblings (`Seal`/`Open` and
`Seal_Combined`/`Open_Combined`) rather than scattered `_detached` variants,
and an optional `Crypto.Safe` layer makes `Key`, `Nonce`, `Auth_Tag` and
`Signature` distinct types so the compiler rejects a nonce passed where a key
is expected.  No raw pointers ever escape the binding.

Call `Crypto.Init` once before use (it is idempotent).

## Quickstart

Install the package (Alpine: `apk add libsodium-ada`), then `with "crypto";`
from a GNAT project file. Building against it needs `libsodium-dev` (the
unversioned `libsodium.so` symlink); running needs `libsodium`.

```ada
-- hash_message.adb
pragma Ada_2022;
with Ada.Text_IO;
with Crypto;

procedure Hash_Message is
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
   Ada.Text_IO.Put_Line
     (Crypto.Hex_Encode (Crypto.Hash_Sha256 (Bytes ("hello"))));
end Hash_Message;
```

```gpr
-- hash_message.gpr
with "crypto";
project Hash_Message is
   for Source_Dirs use (".");
   for Object_Dir use "obj";
   for Exec_Dir use ".";
   for Main use ("hash_message.adb");
end Hash_Message;
```

```sh
GPR_PROJECT_PATH=/usr/share/gpr gprbuild -P hash_message.gpr -p
./hash_message   # 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

## Mapping from C

With the principles in the Introduction you can usually guess the Ada name;
this is the reference for the common ones:

| libsodium C | Ada |
|---|---|
| `crypto_hash_sha256(in, inlen, out)` | `Crypto.Hash_Sha256 (Data)` |
| `crypto_auth(out, in, inlen, k)` | `Crypto.Auth.Authenticate (Data, Key)` |
| `crypto_secretbox_easy(c, m, mlen, n, k)` | `Crypto.Secretbox.Encrypt (Message, Nonce, Key)` |
| `crypto_box_easy(c, m, mlen, n, pk, sk)` | `Crypto.Box.Encrypt (Message, Nonce, Public_Key, Secret_Key)` |
| `crypto_aead_*_encrypt_detached(...)` | `Crypto.Aead.Seal (Message, Nonce, Key, Aad, Kind)` |
| `crypto_sign_detached(sig, &siglen, m, mlen, sk)` | `Crypto.Sign.Sign (Message, Secret_Key)` |
| `crypto_generichash(out, len, in, inlen, key, keylen)` | `Crypto.Generichash.Hash (Data, Length)` |
| `crypto_pwhash_str(out, pw, pwlen, ops, mem)` | `Crypto.Pwhash.Str_Hash (Password, Ops, Mem)` |
| `crypto_kdf_derive_from_key(subkey, len, id, ctx, key)` | `Crypto.Kdf.Derive_From_Key (Subkey_Length, Subkey_Id, Context, Key)` |
| `crypto_scalarmult_curve25519_base(q, n)` | `Crypto.Scalarmult.Mult_Base (N)` |
| `crypto_kem_mlkem768_keypair(pk, sk)` | `Crypto.Kem.Keygen (Mlkem768)` |
| `randombytes_buf(buf, len)` | `Crypto.Random (N)` |
| `sodium_malloc`/`sodium_mlock`/`sodium_mprotect_*` | `Crypto.Secure_Alloc` / `Secure_Buffer` |

## Examples

The `examples/` directory holds five small, runnable programs demonstrating the
main use cases:

| Example | What it shows |
|---|---|
| [`hash.adb`](examples/hash.adb) | SHA-256 one-shot and streaming, HMAC-SHA256 |
| [`aead.adb`](examples/aead.adb) | ChaCha20-Poly1305 authenticated encryption (detached and combined) |
| [`sign.adb`](examples/sign.adb) | Ed25519 signatures, sign/verify and tamper detection |
| [`pwhash.adb`](examples/pwhash.adb) | Argon2id password hashing, verify, rehash check |
| [`safe.adb`](examples/safe.adb) | the strongly-typed `Crypto.Safe` layer |

Build them against an installed `crypto.gpr`:

```sh
cd examples
GPR_PROJECT_PATH=/usr/share/gpr gprbuild -P examples.gpr -p
./hash && ./aead && ./sign && ./pwhash && ./safe
```

## API overview

The root package `Crypto` holds the core utilities and primitives; the
higher-level suites are child packages:

| Package | Primitive(s) |
|---|---|
| `Crypto` | init/version, random bytes, SHA-256/512/SHA-3, HMAC, base-64/hex, constant-time compare, big-number helpers, `memzero`, ChaCha20-Poly1305 AEAD, pad/unpad, `runtime_has_*`, misuse handler, `Secure_Buffer` (`sodium_malloc`/`mlock`/`mprotect`) |
| `Crypto.Raw` | the ABI-stable `crypto_*_statebytes()` size queries the state sizes derive from |
| `Crypto.Safe` | strongly-typed `Key`/`Nonce`/`Auth_Tag`/`Signature`/keys over the raw binding |
| `Crypto.Sign` | Ed25519 signatures (detached/attached/streaming, key conversion) |
| `Crypto.Box` | Curve25519-XSalsa20/XChaCha20-Poly1305 public-key encryption, sealed boxes |
| `Crypto.Scalarmult` | Curve25519 / Ristretto255 / Ed25519 scalar multiplication |
| `Crypto.Kx` | X25519 key exchange |
| `Crypto.Secretbox` | XSalsa20/XChaCha20-Poly1305 symmetric authenticated encryption |
| `Crypto.Secretstream` | XChaCha20-Poly1305 encrypted streams with per-message tags |
| `Crypto.Generichash` | BLAKE2b (keyed/unkeyed, one-shot/streaming) |
| `Crypto.Shorthash` | SipHash-2-4 |
| `Crypto.Auth` | HMAC-SHA512-256 (`crypto_auth`) + streaming HMAC-SHA256/SHA512/SHA512-256 |
| `Crypto.Onetimeauth` | Poly1305 one-time authentication |
| `Crypto.Pwhash` | Argon2id/Argon2i and scrypt (raw + encoded-string) |
| `Crypto.Stream` | XSalsa20 / XChaCha20 / ChaCha20 / Salsa20 (keygen, keystream, XOR) |
| `Crypto.Aead` | ChaCha20-Poly1305, XChaCha20-Poly1305, AES-256-GCM, AEGIS-128L/256 |
| `Crypto.Hash` | streaming SHA-256 / SHA-512 / SHA-3-256 / SHA-3-512 |
| `Crypto.Xof` | SHAKE128 / SHAKE256 extendable-output functions |
| `Crypto.Kdf` | BLAKE2b + HKDF-SHA256/SHA512 key derivation |
| `Crypto.Kem` | ML-KEM-768 / X-Wing key encapsulation |
| `Crypto.Ipcrypt` | 16-byte deterministic block cipher for anonymising fixed-size values |
| `Crypto.Core` | low-level `crypto_core_*` primitives (Salsa cores, Ed25519/Ristretto255 point & scalar arithmetic, Keccak-1600) |

The package specifications themselves (installed with the library) are the
authoritative API reference; see `libsodium-ada(3)` for the man-page overview.

## Security notes

- `Secure_Buffer` allocates page-aligned `sodium_malloc` memory and pins it
  against swap (`mlock`); `Secure_Alloc` raises if the region cannot be locked.
  `Wipe` overwrites with junk then `sodium_memzero` before `Secure_Free`.
- Authentication failures raise `Crypto_Error`; only the `Verify` predicates
  return `False`.
- A `Secure_Buffer` is a single-owner handle — do not copy it (a copy aliases
  the same region and later double-frees).

## License

ISC. See [LICENSE](LICENSE).

Packaged for Alpine by the `ada-on-alpine` aports overlay as
`testing/libsodium-ada`.
