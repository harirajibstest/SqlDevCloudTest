CREATE TABLE "TEST_VSTSRedgate".md_other_objects (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  "NAME" VARCHAR2(4000 BYTE),
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_other_objects_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_other_objects_md_schem_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_other_objects IS 'For storing objects that don''''t belong anywhere else';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_other_objects."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_other_objects.schema_id_fk IS 'Schema to which this object blongs. //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_other_objects."NAME" IS 'Name of this object //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_other_objects.native_sql IS 'The native SQL used to create this object';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_other_objects.native_key IS 'A key that identifies this object at source.';