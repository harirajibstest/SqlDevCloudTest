CREATE TABLE "TEST_VSTSRedgate".md_catalogs (
  "ID" NUMBER NOT NULL,
  connection_id_fk NUMBER NOT NULL,
  catalog_name VARCHAR2(4000 BYTE),
  dummy_flag CHAR DEFAULT 'N',
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_catalogs_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_catalogs_md_connection_fk1 FOREIGN KEY (connection_id_fk) REFERENCES "TEST_VSTSRedgate".md_connections ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_catalogs IS 'Store catalogs in this table.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_catalogs.connection_id_fk IS 'Foreign key into the connections table - Shows what connection this catalog belongs to //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_catalogs.catalog_name IS 'Name of the catalog //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_catalogs.dummy_flag IS 'Flag to show if this catalog is a "dummy" catalog which is used as a placeholder for those platforms that do not support catalogs.  ''N'' signifies that this is NOT a dummy catalog, while ''Y'' signifies that it is.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_catalogs.native_sql IS 'THe SQL used to create this catalog';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_catalogs.native_key IS 'A unique identifier used to identify the catalog at source.';