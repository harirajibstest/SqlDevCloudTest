CREATE TABLE "TEST_VSTSRedgate".dmrs_ext_agent_ext_datas (
  external_agent_id VARCHAR2(70 BYTE) NOT NULL,
  external_agent_ovid VARCHAR2(36 BYTE) NOT NULL,
  external_agent_name VARCHAR2(256 BYTE) NOT NULL,
  external_data_id VARCHAR2(70 BYTE) NOT NULL,
  external_data_ovid VARCHAR2(36 BYTE) NOT NULL,
  external_data_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);