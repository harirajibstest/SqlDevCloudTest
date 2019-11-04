CREATE TABLE "TEST_VSTSRedgate".md_constraint_details (
  "ID" NUMBER NOT NULL,
  ref_flag CHAR DEFAULT 'N',
  constraint_id_fk NUMBER NOT NULL,
  column_id_fk NUMBER,
  column_portion NUMBER,
  constraint_text CLOB,
  detail_order NUMBER NOT NULL,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_constraint_details_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_constraint_details_md__fk1 FOREIGN KEY (constraint_id_fk) REFERENCES "TEST_VSTSRedgate".md_constraints ("ID") ON DELETE CASCADE,
  CONSTRAINT md_constraint_details_md__fk2 FOREIGN KEY (column_id_fk) REFERENCES "TEST_VSTSRedgate".md_columns ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_constraint_details IS 'Constraint details show what columns are "involved" in a constraint.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraint_details."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraint_details.ref_flag IS '"N" or Null signify that this column is the colum that is used in the constraint.  A flag of Y signifies that the colum is a referenced column (i.e. part of a foreign key constraint)';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraint_details.constraint_id_fk IS 'Constraint that this detail belongs to //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraint_details.column_portion IS 'The portion of a column this detail belongs (e.g. for constrints on substrings)';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_constraint_details.constraint_text IS 'The text of the constraint';