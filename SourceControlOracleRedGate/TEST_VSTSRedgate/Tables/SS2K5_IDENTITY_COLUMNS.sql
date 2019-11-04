CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_identity_columns (
  db_id NUMBER(20),
  seed_value NUMBER(20),
  increment_value NUMBER(20),
  "LAST_VALUE" NUMBER(20),
  object_id NUMBER(20) NOT NULL,
  column_id NUMBER(20) NOT NULL
)
ON COMMIT PRESERVE ROWS;