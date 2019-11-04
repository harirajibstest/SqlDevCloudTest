CREATE TABLE "TEST_VSTSRedgate".md_sequences (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  "NAME" VARCHAR2(4000 BYTE) NOT NULL,
  seq_start NUMBER NOT NULL,
  "INCR" NUMBER DEFAULT 1 NOT NULL,
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE) DEFAULT '0' NOT NULL,
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_sequences_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_sequences_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_sequences IS 'For storing information on sequences.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_sequences."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_sequences.schema_id_fk IS 'The schema to which this object belongs. //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_sequences."NAME" IS 'Name of this sequence //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_sequences.seq_start IS 'Starting point of the sequence';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_sequences."INCR" IS 'Increment value of the sequence';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_sequences.native_sql IS 'SQL used to create this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_sequences.native_key IS 'Identifier for this object at source.';