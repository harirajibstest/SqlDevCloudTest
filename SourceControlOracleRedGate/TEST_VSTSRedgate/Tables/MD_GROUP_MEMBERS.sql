CREATE TABLE "TEST_VSTSRedgate".md_group_members (
  "ID" NUMBER NOT NULL,
  group_id_fk NUMBER NOT NULL,
  user_id_fk NUMBER,
  group_member_id_fk NUMBER,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_group_members_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_groupmembers_md_groups_fk1 FOREIGN KEY (group_id_fk) REFERENCES "TEST_VSTSRedgate".md_groups ("ID") ON DELETE CASCADE,
  CONSTRAINT md_groupmembers_md_groups_fk2 FOREIGN KEY (group_member_id_fk) REFERENCES "TEST_VSTSRedgate".md_groups ("ID") ON DELETE CASCADE,
  CONSTRAINT md_groupmembers_md_users_fk1 FOREIGN KEY (user_id_fk) REFERENCES "TEST_VSTSRedgate".md_users ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_group_members IS 'This table is used to store the members of a group.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_group_members."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_group_members.user_id_fk IS 'Id of member';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_group_members.group_member_id_fk IS 'groups can be members of groups';