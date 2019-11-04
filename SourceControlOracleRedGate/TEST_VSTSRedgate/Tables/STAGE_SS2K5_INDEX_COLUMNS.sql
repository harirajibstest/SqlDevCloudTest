CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_index_columns (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  object_id_gen NUMBER(38),
  index_column_id NUMBER(38) NOT NULL,
  object_id NUMBER(38) NOT NULL,
  index_id NUMBER(38) NOT NULL,
  column_id NUMBER(38) NOT NULL,
  is_descending_key NUMBER(38)
)
ON COMMIT PRESERVE ROWS;