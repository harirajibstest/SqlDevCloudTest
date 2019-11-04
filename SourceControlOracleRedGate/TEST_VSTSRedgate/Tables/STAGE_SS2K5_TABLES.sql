CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_tables (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  objid_gen NUMBER(38),
  schema_id_fk NUMBER(38),
  "NAME" VARCHAR2(256 BYTE) NOT NULL,
  object_id NUMBER(38) NOT NULL,
  schema_id NUMBER(38) NOT NULL,
  "TYPE" CHAR(2 CHAR) NOT NULL
)
ON COMMIT PRESERVE ROWS;