CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_all_ri_parents (
  indexname VARCHAR2(128 CHAR),
  parentdb VARCHAR2(128 CHAR),
  parenttable VARCHAR2(128 CHAR),
  parentkeycolumn VARCHAR2(128 CHAR),
  childdb VARCHAR2(128 CHAR),
  childtable VARCHAR2(128 CHAR),
  childkeycolumn VARCHAR2(128 CHAR),
  creatorname VARCHAR2(128 CHAR)
)
ON COMMIT PRESERVE ROWS;