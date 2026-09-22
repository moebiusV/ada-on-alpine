pragma Ada_2022;

--  kline_send: the Ada counterpart to stoplossbot's tools/imsg_kline_send.c.
--  Reads the kucoin_feed CSV on stdin (symbol,ts,open,high,low,close,volume,
--  turnover) and forwards each candle as an IMSG_KLINE frame (type 1) over the
--  unix-domain socket named by argv(1), where fuzzy_search's FS_IMSG_SOCK
--  listener (the C imsg.c reader) consumes it.  Proves the Ada Imsg port
--  interoperates with portable imsg.c byte-for-byte.
--
--  Payload layout -- lock-step with stoplossbot/src/imsg_proto.h imsg_kline_t:
--    sym[64] (NUL-padded) | int64 ts (LE) | 6 * float64 (LE, IEEE754)

with Ada.Command_Line;
with Ada.Streams;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Interfaces;
with GNAT.Sockets;
with GNAT.String_Split;
with Imsg;

procedure Kline_Send is

   use type Interfaces.Unsigned_64;
   use type GNAT.String_Split.Slice_Number;

   IMSG_KLINE : constant := 1;   --  imsg_proto.h: IMSG_KLINE

   Sym_Len     : constant := 64;
   Payload_Len : constant := Sym_Len + 8 + 6 * 8;   --  120

   function Double_Bits is new Ada.Unchecked_Conversion
     (Interfaces.IEEE_Float_64, Interfaces.Unsigned_64);

   procedure Put_LE64
     (D : in out Imsg.Payload; Off : Positive; V : Interfaces.Unsigned_64) is
      Mask : constant Interfaces.Unsigned_64 := 16#FF#;
   begin
      for K in 0 .. 7 loop
         D (Off + K) := Ada.Streams.Stream_Element
           (Interfaces.Shift_Right (V, 8 * K) and Mask);
      end loop;
   end Put_LE64;

   function Pack_Kline
     (Sym : String;
      Ts  : Interfaces.Unsigned_64;
      O, H, L, C, V, T : Interfaces.IEEE_Float_64) return Imsg.Payload
   is
      D : Imsg.Payload (1 .. Payload_Len);
      N : constant Natural := Natural'Min (Sym'Length, Sym_Len);
   begin
      D := [others => 0];
      for J in 1 .. N loop
         D (J) := Ada.Streams.Stream_Element
           (Character'Pos (Sym (Sym'First + J - 1)));
      end loop;
      Put_LE64 (D, Sym_Len + 1, Ts);
      Put_LE64 (D, Sym_Len + 9, Double_Bits (O));
      Put_LE64 (D, Sym_Len + 17, Double_Bits (H));
      Put_LE64 (D, Sym_Len + 25, Double_Bits (L));
      Put_LE64 (D, Sym_Len + 33, Double_Bits (C));
      Put_LE64 (D, Sym_Len + 41, Double_Bits (V));
      Put_LE64 (D, Sym_Len + 49, Double_Bits (T));
      return D;
   end Pack_Kline;

   Sock : GNAT.Sockets.Socket_Type;

begin
   if Ada.Command_Line.Argument_Count /= 1 then
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error, "usage: kline_send SOCKET");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   GNAT.Sockets.Create_Socket
     (Sock, GNAT.Sockets.Family_Unix, GNAT.Sockets.Socket_Stream);
   GNAT.Sockets.Connect_Socket
     (Sock, GNAT.Sockets.Unix_Socket_Address (Ada.Command_Line.Argument (1)));

   loop
      declare
         Line : constant String := Ada.Text_IO.Get_Line;
         Subs : GNAT.String_Split.Slice_Set;
      begin
         GNAT.String_Split.Create (Subs, Line, ",");
         if GNAT.String_Split.Slice_Count (Subs) = 8 then
            declare
               Sym : constant String := GNAT.String_Split.Slice (Subs, 1);
               Ts  : constant Interfaces.Unsigned_64 :=
                 Interfaces.Unsigned_64'Value
                   (GNAT.String_Split.Slice (Subs, 2));
               O : constant Interfaces.IEEE_Float_64 :=
                 Interfaces.IEEE_Float_64'Value
                   (GNAT.String_Split.Slice (Subs, 3));
               H : constant Interfaces.IEEE_Float_64 :=
                 Interfaces.IEEE_Float_64'Value
                   (GNAT.String_Split.Slice (Subs, 4));
               L : constant Interfaces.IEEE_Float_64 :=
                 Interfaces.IEEE_Float_64'Value
                   (GNAT.String_Split.Slice (Subs, 5));
               C : constant Interfaces.IEEE_Float_64 :=
                 Interfaces.IEEE_Float_64'Value
                   (GNAT.String_Split.Slice (Subs, 6));
               V : constant Interfaces.IEEE_Float_64 :=
                 Interfaces.IEEE_Float_64'Value
                   (GNAT.String_Split.Slice (Subs, 7));
               T : constant Interfaces.IEEE_Float_64 :=
                 Interfaces.IEEE_Float_64'Value
                   (GNAT.String_Split.Slice (Subs, 8));
               F : Imsg.Frame (Payload_Len);
            begin
               F.Kind := IMSG_KLINE;
               F.Peer := 0;
               F.Pid  := 0;
               F.Data := Pack_Kline (Sym, Ts, O, H, L, C, V, T);
               Imsg.Send_Frame (Sock, Imsg.Encode (F));
            end;
         end if;
      end;
   end loop;

exception
   when Ada.Text_IO.End_Error =>
      null;   --  EOF on stdin; the socket closes on exit, ending the peer's read
end Kline_Send;
