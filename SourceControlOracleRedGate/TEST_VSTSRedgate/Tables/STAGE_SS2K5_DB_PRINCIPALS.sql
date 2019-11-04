CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_db_principals (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  prinid_gen NUMBER(38),
  default_schema_name VARCHAR2(256 CHAR),
  "TYPE" CHAR(1 CHAR) NOT NULL,
  principal_id NUMBER(38) NOT NULL,
  owning_principal_id NUMBER(38),
  "NAME" VARCHAR2(256 CHAR) NOT NULL,
  "SID" RAW(85)
)
ON COMMIT PRESERVE ROWS;