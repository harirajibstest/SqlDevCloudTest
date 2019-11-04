CREATE TABLE "TEST_VSTSRedgate".md_privileges (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  privilege_name VARCHAR2(4000 BYTE) NOT NULL,
  privelege_object_id NUMBER,
  privelegeobjecttype VARCHAR2(4000 BYTE) NOT NULL,
  privelege_type VARCHAR2(4000 BYTE) NOT NULL,
  admin_option CHAR,
  native_sql CLOB NOT NULL,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_privileges_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_privileges_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_privileges IS 'This table stores privilege information';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges.schema_id_fk IS 'The schema to which this object belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges.privilege_name IS 'The name of the privilege //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges.privelege_object_id IS 'This references the table, view, etc on which the privelege exists.  This can be NULL for things like system wide privileges';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges.privelegeobjecttype IS 'The type the privelege is on (e.g. INDEX)';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges.privelege_type IS 'e.g.select';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges.admin_option IS 'Flag to show if this was granted with admin option.  ''Y'' means it was granted with admin option ''N'' means it was NOT granted with admin option.  NULL means not applicable (e.g. not known, not supported by source platform, etc.)';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges.native_sql IS 'The SQL used to create this privilege at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_privileges.native_key IS 'An identifier for this object at source.';