CREATE TABLE "TEST_VSTSRedgate".md_projects (
  "ID" NUMBER NOT NULL,
  project_name VARCHAR2(4000 BYTE) NOT NULL,
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_projects_pk PRIMARY KEY ("ID")
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_projects IS 'This is a top level container for a set of connections.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_projects."ID" IS 'Primary key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_projects.project_name IS 'Name of the project //OBJECTNAME';