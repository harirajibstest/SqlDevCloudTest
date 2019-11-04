CREATE TABLE "TEST_VSTSRedgate".md_applications (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(4000 BYTE),
  description VARCHAR2(4000 BYTE),
  base_dir VARCHAR2(4000 BYTE),
  output_dir VARCHAR2(4000 BYTE),
  backup_dir VARCHAR2(4000 BYTE),
  "INPLACE" NUMBER,
  project_id_fk NUMBER NOT NULL,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_applications_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_app_proj_fk FOREIGN KEY (project_id_fk) REFERENCES "TEST_VSTSRedgate".md_projects ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_applications IS 'This is the base table for application projects.  It holds the base information for applications associated with a database';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applications."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applications."NAME" IS 'Name of the application suite  //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applications.description IS 'Overview of what the application does.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applications.base_dir IS 'This is the base src directory for the application.  It could be an svn checkout, a clearcase view or something similar';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applications.output_dir IS 'This is the output directory where the scanner will present the converted files, if there are converted or modified.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applications.backup_dir IS 'This is the directory in which the application files are backed up if a backp is chosen';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applications."INPLACE" IS 'Designates whether the changes have been made inplace, in the source directory or not';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applications.project_id_fk IS 'project of the database(s) this application relates to';