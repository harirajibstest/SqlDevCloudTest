CREATE TABLE "TEST_VSTSRedgate".md_group_privileges (
  "ID" NUMBER NOT NULL,
  group_id_fk NUMBER NOT NULL,
  privilege_id_fk NUMBER NOT NULL,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_group_privileges_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_group_privileges_md_gr_fk1 FOREIGN KEY (group_id_fk) REFERENCES "TEST_VSTSRedgate".md_groups ("ID") ON DELETE CASCADE,
  CONSTRAINT md_group_privileges_md_pr_fk1 FOREIGN KEY (privilege_id_fk) REFERENCES "TEST_VSTSRedgate".md_privileges ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_group_privileges IS 'This table stores the privileges granted to a group (or role)';