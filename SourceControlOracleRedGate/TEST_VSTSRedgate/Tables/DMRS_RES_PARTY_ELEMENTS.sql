CREATE TABLE "TEST_VSTSRedgate".dmrs_res_party_elements (
  responsible_party_id VARCHAR2(70 BYTE) NOT NULL,
  responsible_party_ovid VARCHAR2(36 BYTE) NOT NULL,
  responsible_party_name VARCHAR2(256 BYTE) NOT NULL,
  element_id VARCHAR2(70 BYTE) NOT NULL,
  element_ovid VARCHAR2(36 BYTE) NOT NULL,
  element_name VARCHAR2(256 BYTE) NOT NULL,
  element_type VARCHAR2(30 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);