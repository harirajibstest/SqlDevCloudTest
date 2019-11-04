CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_sql_modules (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  objid_gen NUMBER(38),
  definition CLOB,
  object_id NUMBER(38) NOT NULL
)
ON COMMIT PRESERVE ROWS;