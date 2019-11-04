CREATE TABLE "TEST_VSTSRedgate".md_columns (
  "ID" NUMBER NOT NULL,
  table_id_fk NUMBER NOT NULL,
  column_name VARCHAR2(4000 BYTE) NOT NULL,
  column_order NUMBER NOT NULL,
  column_type VARCHAR2(4000 BYTE),
  "PRECISION" NUMBER,
  "SCALE" NUMBER,
  nullable CHAR NOT NULL CONSTRAINT md_columns_nullable_y_n CHECK ((UPPER(NULLABLE) IN ('Y','N'))),
  default_value VARCHAR2(4000 BYTE),
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  datatype_transformed_flag CHAR,
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_by VARCHAR2(255 BYTE),
  created_on DATE DEFAULT sysdate NOT NULL,
  last_updated_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  CONSTRAINT md_columns_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_columns_md_tables_fk1 FOREIGN KEY (table_id_fk) REFERENCES "TEST_VSTSRedgate".md_tables ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_columns IS 'Column information is stored in this table.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.table_id_fk IS 'The table that this column is part of //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.column_name IS 'The name of the column //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.column_order IS 'The order this appears in the table';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.column_type IS 'The type of the column';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns."PRECISION" IS 'The precision on the column';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns."SCALE" IS 'The scale of the column';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.nullable IS 'Yes or No.  Null signifies NO';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.default_value IS 'Default value on the column';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.native_sql IS 'The SQL used to create this column at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.native_key IS 'Unique identifier for this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_columns.datatype_transformed_flag IS 'This is set to ''Y'' to show if the data type was transformed.  This is useful so we don''t apply more than 1 datatype transformation to a column';