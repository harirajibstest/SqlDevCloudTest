CREATE TABLE "TEST_VSTSRedgate".md_groups (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  group_name VARCHAR2(4000 BYTE),
  group_flag CHAR,
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_groups_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_groups_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_groups IS 'Groups of users in a schema';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_groups."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_groups.schema_id_fk IS 'Schema in which this object belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_groups.group_name IS 'Name of the group //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_groups.group_flag IS 'This is a flag to signify a group or a role.  If this is ''R'' it means the group is known as a Role.  Any other value means it is known as a group.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_groups.native_sql IS 'SQL Used to generate this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_groups.native_key IS 'Unique id for this object at source';