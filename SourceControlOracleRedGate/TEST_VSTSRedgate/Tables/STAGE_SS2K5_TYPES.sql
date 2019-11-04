CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_types (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  "NAME" VARCHAR2(256 BYTE) NOT NULL,
  user_type_id NUMBER(38) NOT NULL,
  system_type_id NUMBER(3) NOT NULL,
  schema_id NUMBER(38),
  max_length NUMBER(38),
  "PRECISION" NUMBER(38),
  "SCALE" NUMBER(38)
)
ON COMMIT PRESERVE ROWS;