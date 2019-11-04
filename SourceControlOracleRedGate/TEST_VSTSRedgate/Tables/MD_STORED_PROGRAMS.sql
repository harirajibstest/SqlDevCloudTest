CREATE TABLE "TEST_VSTSRedgate".md_stored_programs (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  programtype VARCHAR2(20 BYTE),
  "NAME" VARCHAR2(4000 BYTE),
  package_id_fk NUMBER,
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  language VARCHAR2(40 BYTE) NOT NULL,
  comments VARCHAR2(4000 BYTE),
  linecount NUMBER,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_stored_programs_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_stored_programs_md_pac_fk1 FOREIGN KEY (package_id_fk) REFERENCES "TEST_VSTSRedgate".md_packages ("ID") ON DELETE CASCADE,
  CONSTRAINT md_stored_programs_md_sch_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_stored_programs IS 'Container for stored programs.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_stored_programs."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_stored_programs.schema_id_fk IS 'Schema to which this object belongs.  Note that the PACKAGE_ID_FK (if present also leads us to the relevant schema), however a stored program may or may not belong in a package.  If it is in a package, then the SCHEMA_ID_FK and the SCHEME_ID_FK in the parent package should match //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_stored_programs.programtype IS 'Java/TSQL/PLSQL, etc.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_stored_programs."NAME" IS 'Name of the stored program //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_stored_programs.package_id_fk IS 'The package to which this object belongs';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_stored_programs.native_sql IS 'The SQL used to create this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_stored_programs.native_key IS 'A unique indetifier for this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_stored_programs.language IS '//PUBLIC';