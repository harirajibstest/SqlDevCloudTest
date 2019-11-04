CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_default_constraints (
  db_id NUMBER(10),
  definition CLOB,
  object_id NUMBER(10) NOT NULL
)
ON COMMIT PRESERVE ROWS;