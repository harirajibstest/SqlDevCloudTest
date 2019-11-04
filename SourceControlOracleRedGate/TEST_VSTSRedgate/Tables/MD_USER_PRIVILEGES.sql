CREATE TABLE "TEST_VSTSRedgate".md_user_privileges (
  "ID" NUMBER NOT NULL,
  user_id_fk NUMBER NOT NULL,
  privilege_id_fk NUMBER,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_udpated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_user_privileges_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_user_privileges_md_pri_fk1 FOREIGN KEY (privilege_id_fk) REFERENCES "TEST_VSTSRedgate".md_privileges ("ID") ON DELETE CASCADE,
  CONSTRAINT md_user_privileges_md_use_fk1 FOREIGN KEY (user_id_fk) REFERENCES "TEST_VSTSRedgate".md_users ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_user_privileges IS 'This table stores privileges granted to individual users';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_privileges."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_privileges.user_id_fk IS 'User';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_privileges.privilege_id_fk IS 'Privilege';