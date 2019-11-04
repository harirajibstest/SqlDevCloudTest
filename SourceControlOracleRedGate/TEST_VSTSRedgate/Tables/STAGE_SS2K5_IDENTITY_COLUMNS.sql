CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_identity_columns (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  object_id_gen NUMBER(38),
  seed_value NUMBER(38),
  increment_value NUMBER(38),
  "LAST_VALUE" NUMBER(38),
  object_id NUMBER(38) NOT NULL,
  column_id NUMBER(38) NOT NULL
)
ON COMMIT PRESERVE ROWS;