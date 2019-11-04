CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".ss2k5_database_role_members (
  db_id NUMBER(10),
  member_principal_id NUMBER(10) NOT NULL,
  role_principal_id NUMBER(10) NOT NULL
)
ON COMMIT PRESERVE ROWS;