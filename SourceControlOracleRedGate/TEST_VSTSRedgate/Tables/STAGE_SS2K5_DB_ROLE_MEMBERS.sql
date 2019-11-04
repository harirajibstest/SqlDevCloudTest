CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_ss2k5_db_role_members (
  svrid_fk NUMBER(38),
  dbid_gen_fk NUMBER(38),
  member_principal_id NUMBER(38) NOT NULL,
  role_principal_id NUMBER(38) NOT NULL
)
ON COMMIT PRESERVE ROWS;