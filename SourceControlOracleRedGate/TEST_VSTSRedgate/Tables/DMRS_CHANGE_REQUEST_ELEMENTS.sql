CREATE TABLE "TEST_VSTSRedgate".dmrs_change_request_elements (
  change_request_id VARCHAR2(70 BYTE) NOT NULL,
  change_request_ovid VARCHAR2(36 BYTE) NOT NULL,
  change_request_name VARCHAR2(256 BYTE) NOT NULL,
  element_id VARCHAR2(70 BYTE) NOT NULL,
  element_ovid VARCHAR2(36 BYTE) NOT NULL,
  element_model_name VARCHAR2(256 BYTE) NOT NULL,
  element_name VARCHAR2(256 BYTE) NOT NULL,
  element_type VARCHAR2(30 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);