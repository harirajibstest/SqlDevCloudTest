CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_offline_fkeys (
  "INDEX" NUMBER,
  dbname VARCHAR2(256 BYTE),
  tabname VARCHAR2(256 BYTE),
  reftabschema VARCHAR2(256 BYTE),
  reftabname VARCHAR2(256 BYTE),
  constname VARCHAR2(256 BYTE),
  colname VARCHAR2(256 BYTE),
  refcolname VARCHAR2(256 BYTE),
  "TYPE" CHAR
)
ON COMMIT PRESERVE ROWS;