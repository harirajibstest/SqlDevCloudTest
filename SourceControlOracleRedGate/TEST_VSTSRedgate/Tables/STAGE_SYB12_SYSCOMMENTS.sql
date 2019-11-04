CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_syb12_syscomments (
  svrid_fk NUMBER,
  dbid_gen_fk NUMBER,
  id_gen_fk NUMBER,
  "ID" NUMBER,
  db_number NUMBER,
  colid NUMBER,
  texttype NUMBER,
  language NUMBER,
  "TEXT" VARCHAR2(255 CHAR),
  colid2 NUMBER,
  status NUMBER
)
ON COMMIT PRESERVE ROWS;