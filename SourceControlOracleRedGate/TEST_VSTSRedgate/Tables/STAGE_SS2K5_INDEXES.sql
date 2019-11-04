CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_indexes (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  object_id_gen NUMBER(38),
  object_id NUMBER(38) NOT NULL,
  index_id NUMBER(38) NOT NULL,
  "NAME" VARCHAR2(256 CHAR),
  is_unique NUMBER(1),
  is_primary_key NUMBER(1)
)
ON COMMIT PRESERVE ROWS;