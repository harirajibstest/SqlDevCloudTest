CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_schemata (
  db_id NUMBER(10),
  schema_owner VARCHAR2(256 BYTE) NOT NULL,
  schema_name VARCHAR2(256 BYTE) NOT NULL
)
ON COMMIT PRESERVE ROWS;