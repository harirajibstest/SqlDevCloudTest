CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_syb12_sysconstraints (
  svrid_fk NUMBER,
  dbid_gen_fk NUMBER,
  table_id_gen_fk NUMBER,
  constraint_gen NUMBER,
  colid NUMBER,
  constrid NUMBER,
  tableid NUMBER,
  "ERROR" NUMBER,
  status NUMBER,
  spare2 NUMBER
)
ON COMMIT PRESERVE ROWS;