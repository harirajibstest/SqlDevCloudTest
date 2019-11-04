CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_tables (
  mdid NUMBER,
  databasename VARCHAR2(128 CHAR),
  tablename VARCHAR2(128 CHAR),
  tablekind CHAR(1 CHAR),
  creatorname VARCHAR2(128 CHAR),
  requesttext CLOB,
  commentstring VARCHAR2(255 CHAR),
  commitopt CHAR(1 CHAR)
)
ON COMMIT PRESERVE ROWS;