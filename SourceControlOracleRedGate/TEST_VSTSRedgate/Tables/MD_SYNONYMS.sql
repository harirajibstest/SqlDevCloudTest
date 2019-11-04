CREATE TABLE "TEST_VSTSRedgate".md_synonyms (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  "NAME" VARCHAR2(4000 BYTE) NOT NULL,
  synonym_for_id NUMBER NOT NULL,
  for_object_type VARCHAR2(4000 BYTE) NOT NULL,
  private_visibility CHAR,
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_synonyms_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_synonyms_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_synonyms IS 'For storing synonym information.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_synonyms."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_synonyms.schema_id_fk IS 'The schema to which this object belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_synonyms."NAME" IS 'Synonym name //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_synonyms.synonym_for_id IS 'What object this is a synonym for';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_synonyms.for_object_type IS 'The type this is a synonym for (e.g. INDEX)';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_synonyms.private_visibility IS 'Visibility - Private or Public.  If Private_visibility = ''Y'' means this is a private synonym.  Anything else means it is a public synonym';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_synonyms.native_sql IS 'The SQL used to create this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_synonyms.native_key IS 'An identifier for this object at source.';