CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_database_principals (
  db_id NUMBER(10),
  default_schema_name VARCHAR2(256 BYTE),
  "TYPE" CHAR NOT NULL,
  principal_id NUMBER(10) NOT NULL,
  owning_principal_id NUMBER(10),
  "NAME" VARCHAR2(256 BYTE) NOT NULL,
  "SID" RAW(85)
)
ON COMMIT PRESERVE ROWS;