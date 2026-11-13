--  Closing a connection that has an FTS5 table crashes (SIGSEGV, reported by
--  GNAT as STORAGE_ERROR s-intman.adb:136).  Build against gnatcoll_sqlite
--  linked to a SQLite with FTS5; with the patch it exits normally.
with Ada.Text_IO;
with GNATCOLL.SQL.Exec;    use GNATCOLL.SQL.Exec;
with GNATCOLL.SQL.Sqlite;

procedure Repro is
   Desc : constant Database_Description :=
     GNATCOLL.SQL.Sqlite.Setup (":memory:");
   DB   : Database_Connection := Build_Connection (Desc);
begin
   Execute (DB, "CREATE VIRTUAL TABLE t USING fts5 (x)");
   Commit_Or_Rollback (DB);
   Ada.Text_IO.Put_Line ("created");
   Free (DB);                       --  crashes without the patch
   Ada.Text_IO.Put_Line ("closed");
end Repro;
