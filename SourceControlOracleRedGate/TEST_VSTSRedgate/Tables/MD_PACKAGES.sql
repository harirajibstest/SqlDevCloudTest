CREATE TABLE "TEST_VSTSRedgate".md_packages (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  "NAME" VARCHAR2(4000 BYTE) NOT NULL,
  package_header CLOB,
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  language VARCHAR2(40 BYTE) NOT NULL,
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_packages_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_packages_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_packages IS 'For storing packages';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_packages."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_packages.schema_id_fk IS 'the schema in which this package resides //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_packages."NAME" IS 'Name of this package //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_packages.native_sql IS 'The SQL used to create this package at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_packages.native_key IS 'A unique identifer for this object at source.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_packages.language IS '//PUBLIC';