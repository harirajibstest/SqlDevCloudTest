CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".syb12_sysusers (
  db_id NUMBER(10),
  suid NUMBER(10),
  db_uid NUMBER(10) NOT NULL,
  gid NUMBER(10),
  "NAME" VARCHAR2(256 BYTE),
  environ VARCHAR2(256 BYTE)
)
ON COMMIT PRESERVE ROWS;