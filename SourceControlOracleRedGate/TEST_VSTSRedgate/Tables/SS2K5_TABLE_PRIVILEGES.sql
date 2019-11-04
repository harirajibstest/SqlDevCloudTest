CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_table_privileges (
  db_id NUMBER(10),
  grantor VARCHAR2(256 BYTE),
  table_schema VARCHAR2(256 BYTE),
  table_name VARCHAR2(256 BYTE) NOT NULL,
  privilege_type VARCHAR2(256 BYTE),
  is_grantable VARCHAR2(256 BYTE),
  grantee VARCHAR2(256 BYTE)
)
ON COMMIT PRESERVE ROWS;