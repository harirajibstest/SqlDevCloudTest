CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_indices (
  mdid NUMBER,
  databasename VARCHAR2(128 CHAR),
  tablename VARCHAR2(128 CHAR),
  indexnumber NUMBER(10),
  "INDEXTYPE" CHAR(1 CHAR),
  uniqueflag CHAR(1 CHAR),
  indexname VARCHAR2(128 CHAR),
  columnname VARCHAR2(128 CHAR),
  columnposition NUMBER(10),
  creatorname VARCHAR2(128 CHAR),
  indexmode CHAR(1 CHAR)
)
ON COMMIT PRESERVE ROWS;