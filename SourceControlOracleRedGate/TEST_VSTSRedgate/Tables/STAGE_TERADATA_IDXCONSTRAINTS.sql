CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_idxconstraints (
  mdid NUMBER,
  databasename VARCHAR2(128 CHAR),
  tablename VARCHAR2(128 CHAR),
  indexname VARCHAR2(128 CHAR),
  indexnumber NUMBER(10),
  constrainttype CHAR,
  constrainttext CLOB
)
ON COMMIT PRESERVE ROWS;