CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_syb12_sysobjects (
  svrid_fk NUMBER,
  dbid_gen_fk NUMBER,
  objid_gen NUMBER,
  suid_gen_fk NUMBER,
  "NAME" VARCHAR2(256 BYTE),
  "ID" NUMBER NOT NULL,
  db_uid NUMBER,
  db_type VARCHAR2(256 BYTE),
  userstat NUMBER,
  sysstat NUMBER,
  indexdel NUMBER,
  schematacnt NUMBER,
  sysstat2 NUMBER,
  crdate VARCHAR2(255 BYTE),
  expdate VARCHAR2(255 BYTE),
  deltrig NUMBER,
  instrig NUMBER,
  updtrig NUMBER,
  seltrig NUMBER,
  ckfirst NUMBER,
  db_cache NUMBER,
  audflags NUMBER,
  objspare NUMBER,
  versionts RAW(255),
  loginname VARCHAR2(255 BYTE)
)
ON COMMIT PRESERVE ROWS;