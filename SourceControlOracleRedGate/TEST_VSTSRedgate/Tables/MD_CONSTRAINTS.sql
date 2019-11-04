CREATE TABLE "TEST_VSTSRedgate".md_constraints (
  "ID" NUMBER NOT NULL,
  delete_clause VARCHAR2(4000 BYTE),
  "NAME" VARCHAR2(4000 BYTE),
  constraint_type VARCHAR2(4000 BYTE),
  table_id_fk NUMBER NOT NULL,
  reftable_id_fk NUMBER,
  constraint_text CLOB,
  language VARCHAR2(40 BYTE) NOT NULL,
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_constraints_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_constraints_md_tables_fk1 FOREIGN KEY (table_id_fk) REFERENCES "TEST_VSTSRedgate".md_tables ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_constraints IS 'Table for storing information about a constraint';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraints."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraints.delete_clause IS 'delete option , can be either CASCADE, RESTRICT or NULL';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraints."NAME" IS 'Name of the constraint //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraints.constraint_type IS 'Type of the constraint (e.g. CHECK)';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraints.table_id_fk IS 'Table on which this constraint exists //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraints.reftable_id_fk IS 'Used in foreign keys - this gives the table that we refer to.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraints.constraint_text IS 'The text of the constraint';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraints.language IS '//PUBLIC';