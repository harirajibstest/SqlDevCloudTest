CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_syb12_systypes (
  svrid_fk NUMBER,
  dbid_gen_fk NUMBER,
  db_uid NUMBER,
  usertype NUMBER,
  variable NUMBER(1),
  allownulls NUMBER(1),
  db_type NUMBER,
  "LENGTH" NUMBER,
  tdefault NUMBER,
  domain NUMBER,
  "NAME" VARCHAR2(255 BYTE),
  printfmt VARCHAR2(255 BYTE),
  prec NUMBER,
  "SCALE" NUMBER,
  ident NUMBER,
  heirarchy NUMBER,
  accessrule NUMBER(12),
  xtypeid NUMBER(12),
  vxdbid NUMBER(12)
)
ON COMMIT PRESERVE ROWS;