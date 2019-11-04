CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_schemata (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  suid_gen NUMBER(38),
  schema_owner VARCHAR2(256 CHAR) NOT NULL,
  schema_name VARCHAR2(256 CHAR) NOT NULL
)
ON COMMIT PRESERVE ROWS;