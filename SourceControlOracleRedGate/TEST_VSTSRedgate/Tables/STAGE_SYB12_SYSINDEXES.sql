CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_syb12_sysindexes (
  svrid_fk NUMBER,
  dbid_gen_fk NUMBER,
  id_gen_fk NUMBER,
  indid_gen NUMBER,
  table_id NUMBER,
  index_name VARCHAR2(256 BYTE) NOT NULL,
  "INDEX_DESC" VARCHAR2(1000 BYTE),
  index_keys VARCHAR2(1000 BYTE),
  keycnt NUMBER(7),
  indid NUMBER(7),
  status NUMBER(7),
  status2 NUMBER(7)
)
ON COMMIT PRESERVE ROWS;