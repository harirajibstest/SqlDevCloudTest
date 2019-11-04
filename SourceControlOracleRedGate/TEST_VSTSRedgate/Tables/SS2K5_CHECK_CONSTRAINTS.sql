CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_check_constraints (
  db_id NUMBER(10),
  object_id NUMBER(10) NOT NULL,
  parent_column_id NUMBER(10) NOT NULL,
  definition CLOB
)
ON COMMIT PRESERVE ROWS;