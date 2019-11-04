CREATE TABLE "TEST_VSTSRedgate".md_migr_parameter (
  "ID" NUMBER NOT NULL,
  connection_id_fk NUMBER NOT NULL,
  object_id NUMBER NOT NULL,
  object_type VARCHAR2(4000 BYTE) NOT NULL,
  param_existing NUMBER NOT NULL,
  param_order NUMBER NOT NULL,
  param_name VARCHAR2(4000 BYTE) NOT NULL,
  param_type VARCHAR2(4000 BYTE) NOT NULL,
  param_data_type VARCHAR2(4000 BYTE) NOT NULL,
  percision NUMBER,
  "SCALE" NUMBER,
  nullable CHAR NOT NULL,
  default_value VARCHAR2(4000 BYTE),
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT migr_parameter_pk PRIMARY KEY ("ID"),
  CONSTRAINT migr_parameter_fk FOREIGN KEY (connection_id_fk) REFERENCES "TEST_VSTSRedgate".md_connections ("ID") ON DELETE CASCADE
);
COMMENT ON COLUMN "TEST_VSTSRedgate".md_migr_parameter.connection_id_fk IS 'the connection in which this belongs //PARENTFIELD';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_migr_parameter.param_existing IS '1 represents a new parameter for PL/SQL that was not present in the origional. 0 represents a n existing parameter that was present in the origional';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_migr_parameter.param_order IS 'IF -1 THEN THIS PARAM IS A RETURN PARAMETER. 1 WILL BE THE FIRST PARAMETER IN THE PARAMETER LIST';