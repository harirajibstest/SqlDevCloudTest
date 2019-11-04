CREATE TABLE "TEST_VSTSRedgate".md_views (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  view_name VARCHAR2(4000 BYTE),
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  language VARCHAR2(40 BYTE) NOT NULL,
  comments VARCHAR2(4000 BYTE),
  linecount NUMBER,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_views_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_views_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_views IS 'For storing information on views.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_views."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_views.schema_id_fk IS 'The schema to which this obect blongs. //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_views.view_name IS 'The name of the view //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_views.native_sql IS 'The SQL used to create this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_views.native_key IS 'An identifier for this object at source.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_views.language IS '//PUBLIC';