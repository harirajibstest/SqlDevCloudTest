CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_fkeys (
  mdid1 NUMBER,
  mdid2 NUMBER,
  tableschema VARCHAR2(128 CHAR),
  tablename VARCHAR2(128 CHAR),
  reftableschema VARCHAR2(128 CHAR),
  reftablename VARCHAR2(128 CHAR),
  constraintname VARCHAR2(128 CHAR),
  columnname VARCHAR2(128 CHAR),
  refcolumnname VARCHAR2(128 CHAR),
  refkeyname VARCHAR2(128 CHAR),
  columnseq NUMBER(10),
  referenceidx NUMBER(10),
  fkeyid NUMBER(10),
  parentkeyid NUMBER(10)
)
ON COMMIT PRESERVE ROWS;