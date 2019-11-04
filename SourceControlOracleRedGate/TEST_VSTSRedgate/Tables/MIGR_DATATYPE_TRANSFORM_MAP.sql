CREATE TABLE "TEST_VSTSRedgate".migr_datatype_transform_map (
  "ID" NUMBER NOT NULL,
  project_id_fk NUMBER NOT NULL,
  map_name VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT migr_datatype_transform_m_pk PRIMARY KEY ("ID"),
  CONSTRAINT migr_datatype_transform_m_fk1 FOREIGN KEY (project_id_fk) REFERENCES "TEST_VSTSRedgate".md_projects ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".migr_datatype_transform_map IS 'Table for storing data type maps.  A map is simply a collection of rules';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_map."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_map.project_id_fk IS '//PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".migr_datatype_transform_map.map_name IS 'A name for the map';