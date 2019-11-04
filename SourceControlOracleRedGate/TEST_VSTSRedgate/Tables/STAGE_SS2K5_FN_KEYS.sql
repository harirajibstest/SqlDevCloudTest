CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_fn_keys (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  object_id_gen NUMBER(38),
  "NAME" VARCHAR2(256 CHAR) NOT NULL,
  object_id NUMBER(38) NOT NULL
)
ON COMMIT PRESERVE ROWS;