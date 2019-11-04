CREATE TABLE "TEST_VSTSRedgate".md_users (
  "ID" NUMBER NOT NULL,
  schema_id_fk NUMBER NOT NULL,
  username VARCHAR2(4000 BYTE) NOT NULL,
  "PASSWORD" VARCHAR2(4000 BYTE),
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  comments VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_users_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_users_md_schemas_fk1 FOREIGN KEY (schema_id_fk) REFERENCES "TEST_VSTSRedgate".md_schemas ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_users IS 'User information.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_users."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_users.schema_id_fk IS 'Shema in which this object belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_users.username IS 'Username for login //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_users."PASSWORD" IS 'Password for login';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_users.native_sql IS 'SQL Used to create this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_users.native_key IS 'Unique identifier for this object at source.';