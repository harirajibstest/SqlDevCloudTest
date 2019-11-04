CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_table_privileges (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  suid_gen_fk NUMBER(38),
  grantor VARCHAR2(256 CHAR),
  table_schema VARCHAR2(256 CHAR),
  table_name VARCHAR2(256 CHAR) NOT NULL,
  privilege_type VARCHAR2(256 CHAR),
  is_grantable VARCHAR2(256 CHAR),
  grantee VARCHAR2(256 CHAR)
)
ON COMMIT PRESERVE ROWS;