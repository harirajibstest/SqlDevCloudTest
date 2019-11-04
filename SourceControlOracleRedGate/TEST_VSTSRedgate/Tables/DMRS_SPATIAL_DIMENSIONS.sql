CREATE TABLE "TEST_VSTSRedgate".dmrs_spatial_dimensions (
  definition_id VARCHAR2(70 BYTE) NOT NULL,
  definition_ovid VARCHAR2(36 BYTE) NOT NULL,
  definition_name VARCHAR2(256 BYTE) NOT NULL,
  dimension_name VARCHAR2(256 BYTE) NOT NULL,
  low_boundary NUMBER NOT NULL,
  upper_boundary NUMBER NOT NULL,
  tolerance NUMBER,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);