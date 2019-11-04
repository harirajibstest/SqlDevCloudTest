CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_joinindices (
  databasename VARCHAR2(128 CHAR),
  tablename VARCHAR2(128 CHAR),
  joinidxdatabasename VARCHAR2(128 CHAR),
  joinidxxname VARCHAR2(128 CHAR),
  "INDEXTYPE" CHAR(1 CHAR)
)
ON COMMIT PRESERVE ROWS;