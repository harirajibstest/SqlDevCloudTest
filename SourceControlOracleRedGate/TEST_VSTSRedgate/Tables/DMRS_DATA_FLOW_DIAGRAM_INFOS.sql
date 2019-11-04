CREATE TABLE "TEST_VSTSRedgate".dmrs_data_flow_diagram_infos (
  diagram_id VARCHAR2(70 BYTE) NOT NULL,
  diagram_ovid VARCHAR2(36 BYTE) NOT NULL,
  diagram_name VARCHAR2(256 BYTE) NOT NULL,
  info_store_id VARCHAR2(70 BYTE) NOT NULL,
  info_store_ovid VARCHAR2(36 BYTE) NOT NULL,
  info_store_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);