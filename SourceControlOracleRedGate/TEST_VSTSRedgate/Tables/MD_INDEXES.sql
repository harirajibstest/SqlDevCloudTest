CREATE TABLE "TEST_VSTSRedgate".md_indexes (
  "ID" NUMBER NOT NULL,
  index_type VARCHAR2(4000 BYTE),
  table_id_fk NUMBER NOT NULL,
  index_name VARCHAR2(4000 BYTE),
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(4000 BYTE),
  CONSTRAINT md_indexes_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_indexes_md_tables_fk1 FOREIGN KEY (table_id_fk) REFERENCES "TEST_VSTSRedgate".md_tables ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_indexes IS 'This table is used to store information about the indexes in a schema';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_indexes."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_indexes.index_type IS 'Type of the index e.g. PRIMARY';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_indexes.table_id_fk IS 'Table that this index is on //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_indexes.index_name IS 'Name of the index //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_indexes.native_sql IS 'SQL used to create the index at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_indexes.native_key IS 'A unique identifier for this object at the source';