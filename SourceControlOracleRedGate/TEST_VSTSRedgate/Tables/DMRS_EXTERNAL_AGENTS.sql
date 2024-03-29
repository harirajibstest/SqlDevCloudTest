CREATE TABLE "TEST_VSTSRedgate".dmrs_external_agents (
  external_agent_id VARCHAR2(70 BYTE) NOT NULL,
  external_agent_ovid VARCHAR2(36 BYTE) NOT NULL,
  external_agent_name VARCHAR2(256 BYTE) NOT NULL,
  diagram_id VARCHAR2(70 BYTE) NOT NULL,
  diagram_ovid VARCHAR2(36 BYTE) NOT NULL,
  diagram_name VARCHAR2(256 BYTE) NOT NULL,
  external_agent_type VARCHAR2(30 BYTE),
  file_location VARCHAR2(256 BYTE),
  file_source VARCHAR2(256 BYTE),
  file_name VARCHAR2(256 BYTE),
  file_type VARCHAR2(30 BYTE),
  file_owner VARCHAR2(256 BYTE),
  data_capture_type VARCHAR2(30 BYTE),
  field_separator CHAR,
  text_delimiter CHAR,
  skip_records NUMBER(10),
  self_describing CHAR,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);