CREATE TABLE "TEST_VSTSRedgate".md_applicationfiles (
  "ID" NUMBER NOT NULL,
  applications_id_fk NUMBER NOT NULL,
  "NAME" VARCHAR2(200 BYTE) NOT NULL,
  uri VARCHAR2(4000 BYTE) NOT NULL,
  "TYPE" VARCHAR2(100 BYTE) NOT NULL,
  "STATE" VARCHAR2(100 BYTE) NOT NULL,
  language VARCHAR2(100 BYTE),
  loc NUMBER,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(4000 BYTE),
  updated_on DATE,
  updated_by VARCHAR2(4000 BYTE),
  CONSTRAINT md_applicationfiles_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_file_app_fk FOREIGN KEY (applications_id_fk) REFERENCES "TEST_VSTSRedgate".md_applications ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_applicationfiles IS 'Holds a tuple for each file that is being processed whether it is changed or not.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles."NAME" IS 'file name  //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles.uri IS 'The uri is the part of the file url after the base dir has been removed.  See MD_APPLICATION for base dir';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles."TYPE" IS 'This will denote the type of file we have, including DIR, FILE (text), BINARY, IGNORE (where we choose to ignore files)';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles."STATE" IS 'State will be how this file is operated on.  For example. it will be OPEN, NEW, FIXED, IGNORED, REVIEWED, COMPLETE';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles.language IS 'Language of the file that has been processed.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles.security_group_id IS 'APEX';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles.created_on IS 'APEX';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles.created_by IS 'APEX';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles.updated_on IS 'APEX';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_applicationfiles.updated_by IS 'APEX';