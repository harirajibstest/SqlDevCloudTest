CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_fn_key_columns (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  constraint_column_id NUMBER(38) NOT NULL,
  constraint_object_id NUMBER(38) NOT NULL,
  parent_object_id NUMBER(38) NOT NULL,
  parent_column_id NUMBER(38) NOT NULL,
  referenced_column_id NUMBER(38) NOT NULL,
  referenced_object_id NUMBER(38) NOT NULL
)
ON COMMIT PRESERVE ROWS;