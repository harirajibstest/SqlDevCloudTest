CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_offline_check (
  "INDEX" NUMBER,
  dbname VARCHAR2(256 BYTE),
  tabname VARCHAR2(256 BYTE),
  constraint_name VARCHAR2(256 BYTE),
  search_condition VARCHAR2(4000 BYTE)
)
ON COMMIT PRESERVE ROWS;