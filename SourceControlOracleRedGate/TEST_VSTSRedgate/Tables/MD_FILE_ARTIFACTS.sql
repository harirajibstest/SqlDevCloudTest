CREATE TABLE "TEST_VSTSRedgate".md_file_artifacts (
  "ID" NUMBER NOT NULL CONSTRAINT md_app_file_art_nonull CHECK ("ID" IS NOT NULL),
  applicationfiles_id NUMBER NOT NULL CONSTRAINT md_appl_file_fk_nonull CHECK ("APPLICATIONFILES_ID" IS NOT NULL),
  "PATTERN" VARCHAR2(4000 BYTE),
  string_found VARCHAR2(4000 BYTE),
  string_replaced VARCHAR2(4000 BYTE),
  "TYPE" VARCHAR2(200 BYTE),
  status VARCHAR2(4000 BYTE),
  line NUMBER,
  pattern_start NUMBER,
  pattern_end NUMBER,
  due_date DATE,
  db_type VARCHAR2(100 BYTE),
  code_type VARCHAR2(1000 BYTE),
  description VARCHAR2(4000 BYTE),
  "PRIORITY" NUMBER(*,0),
  security_group_id VARCHAR2(20 BYTE) DEFAULT '0' NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(4000 BYTE),
  last_updated DATE,
  last_updated_by VARCHAR2(4000 BYTE),
  CONSTRAINT md_file_artifacts_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_artifact_file_fk FOREIGN KEY (applicationfiles_id) REFERENCES "TEST_VSTSRedgate".md_applicationfiles ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_file_artifacts IS 'Holds a tuple for each interesting thing the scanner finds in a file';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts."PATTERN" IS 'Pattern used to search source file for interesting artifiacts';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts.string_found IS 'String found in source from the pattern supplied';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts.string_replaced IS 'This is the string which replace the string found if it was replaced.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts."TYPE" IS 'This is the type of the replacement.  It could be a straight replace from a replacement pattern, or we could have passed the string to a translator which would change the string depending on the database.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts.status IS 'Pattern used to search source file for interesting artifiacts';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts.due_date IS 'Due date is used by the TODO mechanism to manage the validation and work to complete this change';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts.db_type IS 'Source database calls type';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts.code_type IS 'Source code db api, like dblib, jdbc';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts.description IS 'This is a description of the artifact which will have a default generated by the scanner and then can be modified by the user to be more appropriate for their use';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_file_artifacts."PRIORITY" IS 'The priority is set for the TODOs so they can be managed by the user';