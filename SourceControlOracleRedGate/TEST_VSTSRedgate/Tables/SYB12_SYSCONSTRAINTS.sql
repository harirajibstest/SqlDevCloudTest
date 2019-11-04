CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".syb12_sysconstraints (
  db_id NUMBER(10),
  table_id NUMBER(10),
  constraint_name VARCHAR2(256 BYTE) NOT NULL,
  db_definition VARCHAR2(1000 BYTE)
)
ON COMMIT PRESERVE ROWS;