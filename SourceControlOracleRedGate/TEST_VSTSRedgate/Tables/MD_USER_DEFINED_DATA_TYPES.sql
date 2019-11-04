CREATE TABLE "TEST_VSTSRedgate".md_user_defined_data_types (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  data_type_name VARCHAR2(4000 BYTE) NOT NULL,
  definition VARCHAR2(4000 BYTE) NOT NULL,
  native_sql CLOB NOT NULL,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_user_defined_data_types_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_user_defined_data_type_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_user_defined_data_types IS 'For storing information on user defined data types.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_defined_data_types."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_defined_data_types.schema_id_fk IS 'Schema to which this object blongs. //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_defined_data_types.data_type_name IS 'The name of the data type //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_defined_data_types.definition IS 'The definition of the data type';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_defined_data_types.native_sql IS 'The native SQL used to create this object';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_user_defined_data_types.native_key IS 'An unique identifier for this object at source.';