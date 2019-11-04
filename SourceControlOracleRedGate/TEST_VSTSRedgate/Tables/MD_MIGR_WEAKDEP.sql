CREATE TABLE "TEST_VSTSRedgate".md_migr_weakdep (
  "ID" NUMBER NOT NULL,
  connection_id_fk NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  parent_id NUMBER NOT NULL,
  child_name VARCHAR2(4000 BYTE) NOT NULL,
  parent_type VARCHAR2(4000 BYTE) NOT NULL,
  child_type VARCHAR2(4000 BYTE) NOT NULL,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT migr_weakdep_pk PRIMARY KEY ("ID"),
  CONSTRAINT migr_weakdep_fk1 FOREIGN KEY (connection_id_fk) REFERENCES "TEST_VSTSRedgate".md_connections ("ID") ON DELETE CASCADE,
  CONSTRAINT migr_weakdep_fk2 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON COLUMN "TEST_VSTSRedgate".md_migr_weakdep.child_name IS 'name of the child,  as weak dependencies dont have reference to child id';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_migr_weakdep.parent_type IS 'MD_<tablename>';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_migr_weakdep.child_type IS 'Generic Type (not MD_<tablename>)';