CREATE TABLE "TEST_VSTSRedgate".md_connections (
  "ID" NUMBER NOT NULL,
  project_id_fk NUMBER NOT NULL,
  "TYPE" VARCHAR2(4000 BYTE),
  host VARCHAR2(4000 BYTE),
  port NUMBER,
  username VARCHAR2(4000 BYTE),
  "PASSWORD" VARCHAR2(4000 BYTE),
  dburl VARCHAR2(4000 BYTE),
  "NAME" VARCHAR2(255 BYTE),
  native_sql CLOB,
  status VARCHAR2(30 BYTE),
  num_catalogs NUMBER,
  num_columns NUMBER,
  num_constraints NUMBER,
  num_groups NUMBER,
  num_roles NUMBER,
  num_indexes NUMBER,
  num_other_objects NUMBER,
  num_packages NUMBER,
  num_privileges NUMBER,
  num_schemas NUMBER,
  num_sequences NUMBER,
  num_stored_programs NUMBER,
  num_synonyms NUMBER,
  num_tables NUMBER,
  num_tablespaces NUMBER,
  num_triggers NUMBER,
  num_user_defined_data_types NUMBER,
  num_users NUMBER,
  num_views NUMBER,
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_connections_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_connections_md_project_fk1 FOREIGN KEY (project_id_fk) REFERENCES "TEST_VSTSRedgate".md_projects ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_connections IS 'This table is used to store connection information.  For example, in migrations, we could be carrying out a consolidation which occurs across many connections.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections."ID" IS 'Primary key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections.project_id_fk IS 'The project to which this connection belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections."TYPE" IS 'The type of the connection - For example it could be used to store "ORACLE" or "MYSQL"';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections.host IS 'The host to which this connection connects.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections.port IS 'The port to which this connection connects';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections.username IS 'The username used to make the connection';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections."PASSWORD" IS 'The password used to make this connection';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections.dburl IS 'The database url used to make this connection';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections."NAME" IS '//OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections.native_sql IS 'The native sql used to create this connection';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_connections.status IS 'Status of Migration, = captured,converted,generated,datamoved';