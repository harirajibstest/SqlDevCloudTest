CREATE TABLE "TEST_VSTSRedgate".dmrs_value_ranges (
  dataelement_id VARCHAR2(70 BYTE) NOT NULL,
  dataelement_ovid VARCHAR2(36 BYTE) NOT NULL,
  "TYPE" VARCHAR2(10 BYTE),
  "SEQUENCE" NUMBER NOT NULL,
  begin_value VARCHAR2(256 BYTE) NOT NULL,
  end_value VARCHAR2(256 BYTE),
  short_description VARCHAR2(256 BYTE),
  container_id VARCHAR2(70 BYTE) NOT NULL,
  container_ovid VARCHAR2(36 BYTE) NOT NULL,
  container_name VARCHAR2(256 BYTE) NOT NULL,
  dataelement_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);