CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_check_constraints (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  object_id_gen NUMBER(38),
  object_id NUMBER(38) NOT NULL,
  parent_column_id NUMBER(38) NOT NULL,
  definition CLOB
)
ON COMMIT PRESERVE ROWS;