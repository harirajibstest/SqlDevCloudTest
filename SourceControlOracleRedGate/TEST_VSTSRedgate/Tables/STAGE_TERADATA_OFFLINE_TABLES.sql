CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_offline_tables (
  "INDEX" NUMBER,
  dbname VARCHAR2(256 BYTE),
  tabname VARCHAR2(256 BYTE),
  colname VARCHAR2(256 BYTE),
  typename CHAR(2 BYTE),
  chartype CHAR,
  "LENGTH" NUMBER,
  "SCALE" NUMBER,
  dtotdigits NUMBER,
  dfracdigits NUMBER,
  "NULLS" CHAR,
  "CHECK" VARCHAR2(4000 BYTE),
  columnudtname VARCHAR2(256 BYTE),
  defaultval VARCHAR2(2048 BYTE)
)
ON COMMIT PRESERVE ROWS;