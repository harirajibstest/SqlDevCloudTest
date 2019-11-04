CREATE TABLE "TEST_VSTSRedgate".md_partitions (
  "ID" NUMBER NOT NULL,
  table_id_fk NUMBER NOT NULL,
  native_sql CLOB,
  partition_expression VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_by VARCHAR2(255 BYTE),
  created_on DATE DEFAULT sysdate NOT NULL,
  last_updated_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  CONSTRAINT md_partitions_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_partitions_md_tables_fk1 FOREIGN KEY (table_id_fk) REFERENCES "TEST_VSTSRedgate".md_tables ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_partitions IS 'Partition information is stored in this table.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_partitions."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_partitions.table_id_fk IS 'The table that this partition refers to //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_partitions.native_sql IS 'The SQL used to create this partition at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_partitions.partition_expression IS 'The partition expression';