--  apkbuild_bump — rewrite an APKBUILD's pkgver and sha512sums for a new
--  release.  The tarball is fetched and hashed by release-checksum.sh; this
--  program does the part that is easy to get wrong by hand — the text edit —
--  and validates its inputs before touching the file.
--
--      apkbuild_bump <apkbuild> <version> <sha512-hex>

with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

procedure Apkbuild_Bump is

   use Ada.Strings;
   use Ada.Strings.Unbounded;

   LF     : constant Character := ASCII.LF;
   LF_Str : constant String    := [1 => LF];
   Quote  : constant String    := """";

   function Read_All (Name : String) return String is
      F : Ada.Text_IO.File_Type;
      B : Unbounded_String := Null_Unbounded_String;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Name);
      while not Ada.Text_IO.End_Of_File (F) loop
         Append (B, Ada.Text_IO.Get_Line (F));
         Append (B, LF);
      end loop;
      Ada.Text_IO.Close (F);
      return To_String (B);
   end Read_All;

   procedure Write_All (Name, Content : String) is
      F : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Name);
      Ada.Text_IO.Put (F, Content);
      Ada.Text_IO.Close (F);
   end Write_All;

   --  The value of a "name=" field: from the '=' to the next LF (or EOF).
   function Field (S, Name : String) return String is
      Eq : constant Integer := Fixed.Index (S, Name & "=");
      V  : Integer;
      E  : Integer;
   begin
      if Eq = 0 then
         return "";
      end if;
      V := Eq + Name'Length + 1;
      if V > S'Last then
         return "";
      end if;
      E := Fixed.Index (S, LF_Str, V);
      if E = 0 then
         E := S'Last;
      else
         E := E - 1;
      end if;
      return S (V .. E);
   end Field;

   function Is_Digit (C : Character) return Boolean is (C in '0' .. '9');

   function Valid_Version (V : String) return Boolean is
      Dots : Natural := 0;
   begin
      if V = "" then
         return False;
      end if;
      for C of V loop
         if C = '.' then
            Dots := Dots + 1;
         elsif not Is_Digit (C) then
            return False;
         end if;
      end loop;
      return Dots = 2
        and then V (V'First) /= '.'
        and then V (V'Last) /= '.';
   end Valid_Version;

   function Valid_Hash (H : String) return Boolean is
   begin
      if H'Length /= 128 then
         return False;
      end if;
      for C of H loop
         if C not in '0' .. '9' and then C not in 'a' .. 'f' then
            return False;
         end if;
      end loop;
      return True;
   end Valid_Hash;

   --  Replace the whole "pkgver=..." line, keeping the line's trailing LF.
   function Set_Pkgver (S, Version : String) return String is
      Pos : constant Integer := Fixed.Index (S, "pkgver=");
      LS  : Integer := Pos;
      LE  : Integer;
   begin
      if Pos = 0 then
         return S;
      end if;
      while LS > S'First and then S (LS - 1) /= LF loop
         LS := LS - 1;
      end loop;
      LE := Fixed.Index (S, LF_Str, Pos);
      if LE = 0 then
         LE := S'Last + 1;
      end if;
      return S (S'First .. LS - 1) & "pkgver=" & Version & S (LE .. S'Last);
   end Set_Pkgver;

   --  Replace the sha512sums="..." value (single- or multi-line) with the new
   --  hash and filename, preserving the file's single-/multi-line style.
   function Replace_Sha512sums (S, Hash, Filename : String) return String is
      Pos   : constant Integer := Fixed.Index (S, "sha512sums=");
      Open  : constant Integer :=
        (if Pos = 0 then 0 else Fixed.Index (S, Quote, Pos));
      Close : constant Integer :=
        (if Open = 0 or else Open + 1 > S'Last then 0
         else Fixed.Index (S, Quote, Open + 1));
   begin
      if Pos = 0 or else Open = 0 or else Close = 0 then
         return S;
      end if;
      declare
         Multiline : constant Boolean :=
           Fixed.Index (S (Open + 1 .. Close - 1), LF_Str) /= 0;
         Middle : constant String :=
           (if Multiline then LF & Hash & "    " & Filename & LF
            else Hash & "  " & Filename);
      begin
         return S (S'First .. Pos - 1)
           & "sha512sums=" & Quote & Middle & Quote
           & S (Close + 1 .. S'Last);
      end;
   end Replace_Sha512sums;

   procedure Fail (Msg : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Msg);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end Fail;

begin
   if Ada.Command_Line.Argument_Count /= 3 then
      Fail ("usage: apkbuild_bump <apkbuild> <version> <sha512-hex>");
      return;
   end if;

   declare
      Apkbuild : constant String := Ada.Command_Line.Argument (1);
      Version  : constant String := Ada.Command_Line.Argument (2);
      Hash     : constant String := Ada.Command_Line.Argument (3);
   begin
      if not Valid_Version (Version) then
         Fail ("invalid version: " & Version);
         return;
      end if;
      if not Valid_Hash (Hash) then
         Fail ("invalid sha512: want 128 hex characters");
         return;
      end if;
      if not Ada.Directories.Exists (Apkbuild) then
         Fail ("no such file: " & Apkbuild);
         return;
      end if;

      declare
         Content  : constant String := Read_All (Apkbuild);
         Pkgname  : constant String := Field (Content, "pkgname");
         Old_Ver  : constant String := Field (Content, "pkgver");
         Filename : constant String :=
           (if Pkgname = "" then "" else Pkgname & "-v" & Version & ".tar.gz");
         Updated  : constant String :=
           Replace_Sha512sums (Set_Pkgver (Content, Version), Hash, Filename);
         Temp     : constant String := Apkbuild & ".tmp";
      begin
         if Pkgname = "" then
            Fail ("pkgname= not found in " & Apkbuild);
            return;
         end if;
         if Fixed.Index (Content, "pkgver=") = 0 then
            Fail ("pkgver= not found in " & Apkbuild);
            return;
         end if;
         if Fixed.Index (Content, "sha512sums=") = 0 then
            Fail ("sha512sums= not found in " & Apkbuild);
            return;
         end if;

         Write_All (Temp, Updated);
         Ada.Directories.Delete_File (Apkbuild);
         Ada.Directories.Rename (Temp, Apkbuild);

         Ada.Text_IO.Put_Line ("pkgver:  " & Old_Ver & " -> " & Version);
         Ada.Text_IO.Put_Line ("sha512:  " & Hash);
         Ada.Text_IO.Put_Line ("tarball: " & Filename);
      end;
   end;
end Apkbuild_Bump;
