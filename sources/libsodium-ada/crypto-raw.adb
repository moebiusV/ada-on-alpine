pragma Ada_2022;

package body Crypto.Raw is

   function C_Hash_Sha256_Statebytes return Interfaces.C.size_t
     with Import, Convention => C, External_Name => "crypto_hash_sha256_statebytes";

   function C_Hash_Sha512_Statebytes return Interfaces.C.size_t
     with Import, Convention => C, External_Name => "crypto_hash_sha512_statebytes";

   function C_Generichash_Statebytes return Interfaces.C.size_t
     with Import, Convention => C, External_Name => "crypto_generichash_statebytes";

   function C_Sign_Statebytes return Interfaces.C.size_t
     with Import, Convention => C, External_Name => "crypto_sign_statebytes";

   function C_Secretstream_Statebytes return Interfaces.C.size_t
     with Import, Convention => C,
          External_Name => "crypto_secretstream_xchacha20poly1305_statebytes";

   function Query_Hash_Sha256_Statebytes  return Interfaces.C.size_t
     is (C_Hash_Sha256_Statebytes);
   function Query_Hash_Sha512_Statebytes  return Interfaces.C.size_t
     is (C_Hash_Sha512_Statebytes);
   function Query_Generichash_Statebytes  return Interfaces.C.size_t
     is (C_Generichash_Statebytes);
   function Query_Sign_Statebytes         return Interfaces.C.size_t
     is (C_Sign_Statebytes);
   function Query_Secretstream_Statebytes return Interfaces.C.size_t
     is (C_Secretstream_Statebytes);

end Crypto.Raw;
