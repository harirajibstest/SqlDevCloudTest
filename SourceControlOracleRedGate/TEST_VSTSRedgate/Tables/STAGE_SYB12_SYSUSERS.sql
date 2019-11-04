CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_syb12_sysusers (
  svrid_fk NUMBER,
  dbid_gen_fk NUMBER,
  suid_gen NUMBER,
  gen_id_fk NUMBER,
  suid NUMBER,
  db_uid NUMBER NOT NULL,
  gid NUMBER,
  "NAME" VARCHAR2(256 BYTE),
  environ VARCHAR2(256 BYTE)
)
ON COMMIT PRESERVE ROWS;