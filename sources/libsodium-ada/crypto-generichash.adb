pragma Ada_2022;

with Interfaces.C;
with System;

package body Crypto.Generichash is

   use type Interfaces.C.int;

   type ULL is mod 2 ** 64;
   pragma Convention (C, ULL);

   function Addr (B : Crypto.Byte_Array) return System.Address is
   begin
      if B'Length = 0 then
         return System.Null_Address;
      end if;
      return B (B'First)'Address;
   end Addr;

   procedure Fail (S : String) is
   begin
      raise Crypto.Crypto_Error with S;
   end Fail;

   procedure Check_Length (N : Natural) is
   begin
      if N < Bytes_Min or else N > Bytes_Max then
         Fail ("output length out of range");
      end if;
   end Check_Length;

   function C_Hash
     (Dg : System.Address; Dg_Len : Interfaces.C.size_t;
      Inp : System.Address; Inp_Len : ULL;
      Key : System.Address; Key_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_generichash";

   function C_Init
     (State : System.Address;
      Key   : System.Address; Key_Len : Interfaces.C.size_t;
      Out_Len : Interfaces.C.size_t) return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_generichash_init";

   function C_Update
     (State : System.Address; Inp : System.Address; Inp_Len : ULL)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_generichash_update";

   function C_Final
     (State : System.Address; Dg : System.Address; Dg_Len : Interfaces.C.size_t)
     return Interfaces.C.int
     with Import, Convention => C, External_Name => "crypto_generichash_final";

   function Hash (Data : Crypto.Byte_Array; Length : Natural := Bytes)
      return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. Length);
   begin
      Check_Length (Length);
      if C_Hash (D (1)'Address, Interfaces.C.size_t (Length),
                 Addr (Data), ULL (Data'Length),
                 System.Null_Address, 0) /= 0
      then
         Fail ("generichash failed");
      end if;
      return D;
   end Hash;

   function Hash_Keyed
     (Data, Key : Crypto.Byte_Array; Length : Natural := Bytes)
      return Crypto.Byte_Array
   is
      D : Crypto.Byte_Array (1 .. Length);
   begin
      Check_Length (Length);
      if Key'Length < Key_Size_Min or else Key'Length > Key_Size_Max then
         Fail ("key length out of range");
      end if;
      if C_Hash (D (1)'Address, Interfaces.C.size_t (Length),
                 Addr (Data), ULL (Data'Length),
                 Addr (Key), Interfaces.C.size_t (Key'Length)) /= 0
      then
         Fail ("generichash keyed failed");
      end if;
      return D;
   end Hash_Keyed;

   function New_State (Length : Natural := Bytes) return Stream_State is
      S : Stream_State;
   begin
      Check_Length (Length);
      if C_Init (S.State.Data (1)'Address, System.Null_Address, 0,
                 Interfaces.C.size_t (Length)) /= 0
      then
         Fail ("generichash init failed");
      end if;
      S.Length := Length;
      return S;
   end New_State;

   function New_State_Keyed
     (Key : Crypto.Byte_Array; Length : Natural := Bytes) return Stream_State
   is
      S : Stream_State;
   begin
      Check_Length (Length);
      if Key'Length < Key_Size_Min or else Key'Length > Key_Size_Max then
         Fail ("key length out of range");
      end if;
      if C_Init (S.State.Data (1)'Address, Addr (Key),
                 Interfaces.C.size_t (Key'Length),
                 Interfaces.C.size_t (Length)) /= 0
      then
         Fail ("generichash init failed");
      end if;
      S.Length := Length;
      return S;
   end New_State_Keyed;

   procedure Update (State : in out Stream_State; Chunk : Crypto.Byte_Array) is
   begin
      if C_Update (State.State.Data (1)'Address, Addr (Chunk),
                   ULL (Chunk'Length)) /= 0
      then
         Fail ("generichash update failed");
      end if;
   end Update;

   function Final (State : Stream_State) return Crypto.Byte_Array is
      D : Crypto.Byte_Array (1 .. State.Length);
   begin
      if C_Final (State.State.Data (1)'Address, D (1)'Address,
                  Interfaces.C.size_t (State.Length)) /= 0
      then
         Fail ("generichash final failed");
      end if;
      return D;
   end Final;

end Crypto.Generichash;
