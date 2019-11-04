CREATE TABLE "TEST_VSTSRedgate".md_tables (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  table_name VARCHAR2(4000 BYTE) NOT NULL,
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  qualified_native_name VARCHAR2(4000 BYTE) NOT NULL,
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_tables_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_tables_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_tables IS 'Table used to store information about tables.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tables."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tables.schema_id_fk IS 'Schema in which this table resides //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tables.table_name IS 'Name of the table //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tables.native_sql IS 'SQL Used to create this table at soruce';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_tables.native_key IS 'Unique identifier for this table at source';