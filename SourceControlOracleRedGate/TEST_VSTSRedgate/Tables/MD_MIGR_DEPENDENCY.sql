CREATE TABLE "TEST_VSTSRedgate".md_migr_dependency (
  "ID" NUMBER NOT NULL,
  connection_id_fk NUMBER NOT NULL,
  parent_id NUMBER NOT NULL,
  child_id NUMBER NOT NULL,
  parent_object_type VARCHAR2(4000 BYTE) NOT NULL,
  child_object_type VARCHAR2(4000 BYTE) NOT NULL,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT migr_dependency_pk PRIMARY KEY ("ID"),
  CONSTRAINT migr_dependency_fk FOREIGN KEY (connection_id_fk) REFERENCES "TEST_VSTSRedgate".md_connections ("ID") ON DELETE CASCADE
);
COMMENT ON COLUMN "TEST_VSTSRedgate".md_migr_dependency.connection_id_fk IS 'The connection that this exists in //PARENTFIELD';