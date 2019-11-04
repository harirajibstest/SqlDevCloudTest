CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".syb12_syscomments (
  db_id NUMBER(10),
  "ID" NUMBER(10),
  db_number NUMBER(10),
  colid NUMBER(10),
  texttype NUMBER(10),
  language NUMBER(10),
  "TEXT" VARCHAR2(1000 CHAR),
  colid2 NUMBER(10),
  status NUMBER(10)
)
ON COMMIT PRESERVE ROWS;