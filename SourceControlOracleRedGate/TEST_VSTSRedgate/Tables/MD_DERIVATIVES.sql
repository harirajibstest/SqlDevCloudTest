CREATE TABLE "TEST_VSTSRedgate".md_derivatives (
  "ID" NUMBER NOT NULL,
  src_id NUMBER NOT NULL,
  src_type VARCHAR2(4000 BYTE),
  derived_id NUMBER NOT NULL,
  derived_type VARCHAR2(4000 BYTE),
  derived_connection_id_fk NUMBER NOT NULL,
  transformed CHAR,
  original_identifier VARCHAR2(4000 BYTE),
  new_identifier VARCHAR2(4000 BYTE),
  derived_object_namespace VARCHAR2(40 BYTE),
  derivative_reason VARCHAR2(10 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  enabled CHAR DEFAULT 'Y' CONSTRAINT migrder_chk CHECK (ENABLED = 'Y' OR ENABLED = 'y' OR ENABLED = 'N' OR  ENABLED = 'n'),
  CONSTRAINT migrdreivatives_pk PRIMARY KEY ("ID"),
  CONSTRAINT md_derivatives_md_connect_fk1 FOREIGN KEY (derived_connection_id_fk) REFERENCES "TEST_VSTSRedgate".md_connections ("ID") ON DELETE CASCADE
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_derivatives IS 'This table is used to store objects that are derived from each other.  For example in a migration an auto-increment column in a source model could be mapped to a primary key, and a sequence, and a trigger.  The MD_DERIVATIVES table would store the fact that these 3 objects are derived from the auto-increment column.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_derivatives.transformed IS 'Set this field to ''Y'' if we carry out any sort of transformation on teh derived object.';