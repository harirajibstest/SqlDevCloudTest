CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_udts (
  mdid NUMBER,
  typekind CHAR(1 CHAR),
  typename VARCHAR2(128 CHAR),
  fieldname VARCHAR2(128 CHAR),
  fieldid NUMBER(10),
  fieldtype CHAR(2 CHAR),
  udtname VARCHAR2(128 CHAR),
  chartype NUMBER(10),
  maxlength NUMBER(10),
  decimaltotaldigits NUMBER(10),
  decimalfractionaldigits NUMBER(10),
  "INSTANTIABLE" CHAR(1 CHAR),
  "FINAL" CHAR(1 CHAR)
)
ON COMMIT PRESERVE ROWS;