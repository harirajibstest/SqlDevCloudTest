CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_columns (
  mdid NUMBER,
  databasename VARCHAR2(128 CHAR),
  tablename VARCHAR2(128 CHAR),
  columnname VARCHAR2(128 CHAR),
  columnformat VARCHAR2(128 CHAR),
  columntitle VARCHAR2(256 CHAR),
  columntype CHAR(2 CHAR),
  columnudtname VARCHAR2(128 CHAR),
  columnlength NUMBER(10),
  defaultvalue CLOB,
  nullable CHAR(1 CHAR),
  commentstring VARCHAR2(255 CHAR),
  decimaltotaldigits NUMBER(10),
  decimalfractionaldigits NUMBER(10),
  columnid NUMBER,
  uppercaseflag CHAR(1 CHAR),
  columnconstraint CLOB,
  constraintcount NUMBER(10),
  creatorname VARCHAR2(128 CHAR),
  chartype NUMBER(10),
  idcoltype CHAR(2 CHAR)
)
ON COMMIT PRESERVE ROWS;