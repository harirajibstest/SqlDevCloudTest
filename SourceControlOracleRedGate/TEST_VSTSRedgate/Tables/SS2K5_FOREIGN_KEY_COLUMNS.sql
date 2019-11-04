CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_foreign_key_columns (
  db_id NUMBER(10),
  constraint_column_id NUMBER(10) NOT NULL,
  constraint_object_id NUMBER(10) NOT NULL,
  parent_object_id NUMBER(10) NOT NULL,
  parent_column_id NUMBER(10) NOT NULL,
  referenced_column_id NUMBER(10) NOT NULL,
  referenced_object_id NUMBER(10) NOT NULL
)
ON COMMIT PRESERVE ROWS;