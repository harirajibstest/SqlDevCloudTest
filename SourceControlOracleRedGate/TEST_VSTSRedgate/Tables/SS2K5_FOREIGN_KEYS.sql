CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_foreign_keys (
  db_id NUMBER(10),
  "NAME" VARCHAR2(256 BYTE) NOT NULL,
  object_id NUMBER(10) NOT NULL
)
ON COMMIT PRESERVE ROWS;