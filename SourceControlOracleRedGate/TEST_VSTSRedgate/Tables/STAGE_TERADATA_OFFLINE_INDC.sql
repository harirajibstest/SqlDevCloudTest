CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_offline_indc (
  "INDEX" NUMBER,
  "NAME" VARCHAR2(256 BYTE),
  tablename VARCHAR2(256 BYTE),
  indexname VARCHAR2(256 BYTE),
  indexnumber NUMBER,
  constrainttype CHAR,
  constrainttext CLOB
)
ON COMMIT PRESERVE ROWS;