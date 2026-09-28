pragma Ada_2022;

with Interfaces.C;

--  Raw libsodium ABI surface: the state sizes.  libsodium guarantees these
--  through the crypto_*_statebytes() functions, which return the size of the
--  opaque state struct at runtime (so a binding need not hardcode a struct
--  layout).  This child exposes the runtime query directly, plus a static
--  constant for each (materialised from the same value) where a compile-time
--  constant is required -- a discriminant, an array bound.  The high-level
--  packages derive their state sizes from the static constants here rather
--  than spelling out magic byte counts; the smoke test cross-checks every
--  static constant against its runtime query so a mismatched libsodium is
--  caught at build time.
package Crypto.Raw is

   Hash_Sha256_Statebytes  : constant Natural := 104;
   Hash_Sha512_Statebytes  : constant Natural := 208;
   Generichash_Statebytes  : constant Natural := 384;
   Sign_Statebytes         : constant Natural := 208;
   Secretstream_Statebytes : constant Natural := 52;
   Auth_Hmac_Sha256_Statebytes    : constant Natural := 208;
   Auth_Hmac_Sha512_Statebytes    : constant Natural := 416;
   Auth_Hmac_Sha512256_Statebytes : constant Natural := 416;

   --  Runtime size queries (the crypto_*_statebytes() functions).  Use these
   --  to verify the constants above against the linked libsodium.
   function Query_Hash_Sha256_Statebytes  return Interfaces.C.size_t;
   function Query_Hash_Sha512_Statebytes  return Interfaces.C.size_t;
   function Query_Generichash_Statebytes  return Interfaces.C.size_t;
   function Query_Sign_Statebytes         return Interfaces.C.size_t;
   function Query_Secretstream_Statebytes return Interfaces.C.size_t;
   function Query_Auth_Hmac_Sha256_Statebytes    return Interfaces.C.size_t;
   function Query_Auth_Hmac_Sha512_Statebytes    return Interfaces.C.size_t;
   function Query_Auth_Hmac_Sha512256_Statebytes return Interfaces.C.size_t;

end Crypto.Raw;
