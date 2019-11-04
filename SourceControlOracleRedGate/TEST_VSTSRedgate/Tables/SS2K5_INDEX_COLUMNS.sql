CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_index_columns (
  db_id NUMBER(10),
  index_column_id NUMBER(10) NOT NULL,
  object_id NUMBER(10) NOT NULL,
  index_id NUMBER(10) NOT NULL,
  column_id NUMBER(10) NOT NULL
)
ON COMMIT PRESERVE ROWS;