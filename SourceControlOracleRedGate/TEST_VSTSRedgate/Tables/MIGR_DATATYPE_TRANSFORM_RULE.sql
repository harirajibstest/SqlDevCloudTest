CREATE TABLE "TEST_VSTSRedgate".migr_datatype_transform_rule (
  "ID" NUMBER NOT NULL,
  map_id_fk NUMBER NOT NULL,
  source_data_type_name VARCHAR2(4000 BYTE) NOT NULL,
  source_precision NUMBER,
  source_scale NUMBER,
  target_data_type_name VARCHAR2(4000 BYTE) NOT NULL,
  target_precision NUMBER,
  target_scale NUMBER,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT migr_datatype_transform_r_pk PRIMARY KEY ("ID"),
  CONSTRAINT migr_datatype_transform_r_fk1 FOREIGN KEY (map_id_fk) REFERENCES "TEST_VSTSRedgate".migr_datatype_transform_map ("ID") ON DELETE CASCADE
);
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_rule."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_rule.map_id_fk IS 'The map to which this rule belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_rule.source_data_type_name IS 'Source data type';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_rule.source_precision IS 'Precison to match';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_rule.source_scale IS 'scale to match';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_rule.target_data_type_name IS 'data type name to transform to';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_rule.target_precision IS 'precision to map to ';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_rule.target_scale IS 'scale to map to';