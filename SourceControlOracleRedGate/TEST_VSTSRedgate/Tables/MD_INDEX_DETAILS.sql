CREATE TABLE "TEST_VSTSRedgate".md_index_details (
  "ID" NUMBER NOT NULL,
  index_id_fk NUMBER NOT NULL,
  column_id_fk NUMBER NOT NULL,
  index_portion NUMBER,
  detail_order NUMBER NOT NULL,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_index_details_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_index_details_md_colum_fk1 FOREIGN KEY (column_id_fk) REFERENCES "TEST_VSTSRedgate".md_columns ("ID") ON DELETE CASCADE,
  CONSTRAINT md_index_details_md_index_fk1 FOREIGN KEY (index_id_fk) REFERENCES "TEST_VSTSRedgate".md_indexes ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_index_details IS 'This table stores the details of an index.  It shows what columns are "part" of the index.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_index_details.index_id_fk IS 'The index to which this detail belongs. //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_index_details.index_portion IS 'To support indexing on part of a field';