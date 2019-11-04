CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_offline_pkeys (
  "INDEX" NUMBER,
  dbname VARCHAR2(256 BYTE),
  tabname VARCHAR2(256 BYTE),
  constname VARCHAR2(256 BYTE),
  "TYPE" CHAR,
  colname VARCHAR2(256 BYTE),
  colseq NUMBER,
  uniqueflag CHAR
)
ON COMMIT PRESERVE ROWS;