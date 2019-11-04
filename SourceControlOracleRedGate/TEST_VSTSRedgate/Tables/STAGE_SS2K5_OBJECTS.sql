CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_objects (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  objid_gen NUMBER(38),
  schema_id NUMBER(38) NOT NULL,
  object_id NUMBER(38) NOT NULL,
  "NAME" VARCHAR2(256 CHAR) NOT NULL,
  "TYPE" CHAR(2 CHAR) NOT NULL,
  parent_object_id NUMBER(38) NOT NULL,
  is_ms_shipped NUMBER(1) NOT NULL
)
ON COMMIT PRESERVE ROWS;