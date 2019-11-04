CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_columns (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  id_gen_fk NUMBER(38),
  colid_gen NUMBER(38),
  "NAME" VARCHAR2(256 CHAR),
  rule_object_id NUMBER(38) NOT NULL,
  column_id NUMBER(38) NOT NULL,
  max_length NUMBER(5) NOT NULL,
  "PRECISION" NUMBER(5) NOT NULL,
  "SCALE" NUMBER(5) NOT NULL,
  is_nullable NUMBER(5),
  user_type_id NUMBER(38) NOT NULL,
  system_type_id NUMBER(5) NOT NULL,
  default_object_id NUMBER(38) NOT NULL,
  object_id NUMBER(38) NOT NULL
)
ON COMMIT PRESERVE ROWS;