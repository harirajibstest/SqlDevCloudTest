CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".syb12_systypes (
  db_id NUMBER(10),
  db_uid NUMBER(10),
  usertype NUMBER(10),
  variable NUMBER(1),
  allownulls NUMBER(1),
  db_type NUMBER(10),
  "LENGTH" NUMBER(10),
  tdefault NUMBER(10),
  domain NUMBER(10),
  "NAME" VARCHAR2(255 BYTE),
  printfmt VARCHAR2(255 BYTE),
  prec NUMBER(10),
  "SCALE" NUMBER(10),
  ident NUMBER(10),
  heirarchy NUMBER(10),
  accessrule NUMBER(12),
  xtypeid NUMBER(12),
  vxdbid NUMBER(12)
)
ON COMMIT PRESERVE ROWS;