CREATE TABLE "TEST_VSTSRedgate".md_additional_properties (
  "ID" NUMBER NOT NULL,
  connection_id_fk NUMBER NOT NULL,
  ref_id_fk NUMBER NOT NULL,
  ref_type VARCHAR2(4000 BYTE) NOT NULL,
  property_order NUMBER,
  prop_key VARCHAR2(4000 BYTE) NOT NULL,
  "VALUE" VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_additional_properties_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_additional_properties__fk1 FOREIGN KEY (connection_id_fk) REFERENCES "TEST_VSTSRedgate".md_connections ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_additional_properties IS 'This table is used to store additional properties in key-value pairs.  It is designed to store "other information" that is not supported in the main database object table.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_additional_properties."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_additional_properties.connection_id_fk IS 'Connection to which this belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_additional_properties.ref_id_fk IS 'The object to which this property blongs';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_additional_properties.ref_type IS 'Type of object that this property belongs to';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_additional_properties.property_order IS 'This is to handle a situation where multiple properties have a relevant order, or multiple properties have multiple values';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_additional_properties.prop_key IS 'The keyname for this property';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_additional_properties."VALUE" IS 'The value for this property';