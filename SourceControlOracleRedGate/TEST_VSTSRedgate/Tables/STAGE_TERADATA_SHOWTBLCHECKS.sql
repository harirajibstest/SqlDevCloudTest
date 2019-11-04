CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_showtblchecks (
  mdid NUMBER,
  databasename VARCHAR2(128 CHAR),
  tablename VARCHAR2(128 CHAR),
  checkname VARCHAR2(128 CHAR),
  checktype CHAR,
  tablecheck CLOB,
  columnname VARCHAR2(128 CHAR),
  creatorname VARCHAR2(128 CHAR)
)
ON COMMIT PRESERVE ROWS;