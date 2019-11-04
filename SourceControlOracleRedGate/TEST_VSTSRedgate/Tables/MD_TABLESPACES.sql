CREATE TABLE "TEST_VSTSRedgate".md_tablespaces (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  tablespace_name VARCHAR2(4000 BYTE),
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_tablespaces_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_tablespaces_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_tablespaces IS 'For storing information about tablespaces.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tablespaces."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tablespaces.schema_id_fk IS 'Schema to which this tablespace belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tablespaces.tablespace_name IS 'Name of the table space //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tablespaces.native_sql IS 'The SQL used to create this tablespace';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tablespaces.native_key IS 'A unique identifier for this object at source';