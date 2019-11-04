CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_columns (
  db_id NUMBER(10),
  "NAME" VARCHAR2(256 BYTE),
  rule_object_id NUMBER(10) NOT NULL,
  column_id NUMBER(10) NOT NULL,
  max_length NUMBER(5) NOT NULL,
  "PRECISION" NUMBER(5) NOT NULL,
  "SCALE" NUMBER(5) NOT NULL,
  is_nullable NUMBER(5),
  user_type_id NUMBER(10) NOT NULL,
  system_type_id NUMBER(5) NOT NULL,
  default_object_id NUMBER(10) NOT NULL,
  object_id NUMBER(10) NOT NULL
)
ON COMMIT PRESERVE ROWS;