CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".syb12_sysdatabases (
  db_id NUMBER(10),
  "NAME" VARCHAR2(255 BYTE),
  dbid NUMBER(10),
  db_suid NUMBER(10),
  status NUMBER(10),
  "VERSION" NUMBER(10),
  logptr NUMBER(12),
  crdate VARCHAR2(255 BYTE),
  dumptrdate VARCHAR2(255 BYTE),
  status2 NUMBER(10),
  audflags NUMBER(10),
  deftabaud NUMBER(10),
  defvwaud NUMBER(10),
  defpraud NUMBER(10),
  def_remote_type NUMBER(10),
  def_remote_loc VARCHAR2(255 BYTE),
  status3 NUMBER(10),
  status4 NUMBER(10)
)
ON COMMIT PRESERVE ROWS;