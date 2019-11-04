CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_databases (
  svrid NUMBER,
  mdid NUMBER,
  databasename VARCHAR2(128 CHAR),
  commentstring VARCHAR2(255 CHAR),
  ownername VARCHAR2(128 CHAR)
)
ON COMMIT PRESERVE ROWS;