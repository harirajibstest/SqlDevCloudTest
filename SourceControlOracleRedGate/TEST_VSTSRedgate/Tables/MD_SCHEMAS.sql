CREATE TABLE "TEST_VSTSRedgate".md_schemas (
  "ID" NUMBER NOT NULL,
  catalog_id_fk NUMBER NOT NULL,
  "NAME" VARCHAR2(4000 BYTE),
  "TYPE" CHAR,
  character_set VARCHAR2(4000 BYTE),
  version_tag VARCHAR2(40 BYTE),
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_schemas_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_schemas_md_catalogs_fk1 FOREIGN KEY (catalog_id_fk) REFERENCES "TEST_VSTSRedgate".md_catalogs ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_schemas IS 'This is the holder for schemas';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_schemas."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_schemas.catalog_id_fk IS 'Catalog to which this schema blongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_schemas."NAME" IS 'Name of the schema //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_schemas."TYPE" IS 'Type of this schema.  Eaxamples are ''CAPTURED'' OR ''CONVERTED''';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_schemas.character_set IS 'The characterset of this schema';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_schemas.version_tag IS 'A version string that can be used for tagging/baseling a schema';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_schemas.native_sql IS 'The native SQL used to create this schema';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_schemas.native_key IS 'A unique identifier that this schema is known as in its source state.';