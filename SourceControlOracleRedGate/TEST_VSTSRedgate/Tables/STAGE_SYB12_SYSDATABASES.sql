CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_syb12_sysdatabases (
  svrid_fk NUMBER,
  dbid_gen NUMBER,
  "NAME" VARCHAR2(255 BYTE),
  dbid NUMBER,
  db_suid NUMBER,
  status NUMBER,
  "VERSION" NUMBER,
  logptr NUMBER(12),
  crdate VARCHAR2(255 BYTE),
  dumptrdate VARCHAR2(255 BYTE),
  status2 NUMBER,
  audflags NUMBER,
  deftabaud NUMBER,
  defvwaud NUMBER,
  defpraud NUMBER,
  def_remote_type NUMBER,
  def_remote_loc VARCHAR2(255 BYTE),
  status3 NUMBER,
  status4 NUMBER
)
ON COMMIT PRESERVE ROWS;