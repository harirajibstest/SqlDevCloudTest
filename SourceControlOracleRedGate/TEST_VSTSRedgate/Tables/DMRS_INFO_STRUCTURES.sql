CREATE TABLE "TEST_VSTSRedgate".dmrs_info_structures (
  info_structure_id VARCHAR2(70 BYTE) NOT NULL,
  info_structure_ovid VARCHAR2(36 BYTE) NOT NULL,
  info_structure_name VARCHAR2(256 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  growth_rate_unit VARCHAR2(30 BYTE),
  growth_rate_percent NUMBER(10),
  "VOLUME" NUMBER(10),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);