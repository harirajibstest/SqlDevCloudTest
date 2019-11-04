CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_procedures (
  mdid NUMBER,
  databasename VARCHAR2(128 CHAR),
  procname VARCHAR2(128 CHAR),
  proctype CHAR(2 BYTE),
  requesttext CLOB,
  commentstring VARCHAR2(510 CHAR)
)
ON COMMIT PRESERVE ROWS;