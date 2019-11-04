CREATE TABLE "TEST_VSTSRedgate".dmrs_entityviews (
  entityview_name VARCHAR2(256 BYTE) NOT NULL,
  object_id VARCHAR2(70 BYTE) NOT NULL,
  ovid VARCHAR2(36 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  import_id VARCHAR2(70 BYTE),
  structured_type_id VARCHAR2(70 BYTE),
  structured_type_ovid VARCHAR2(36 BYTE),
  structured_type_name VARCHAR2(256 BYTE),
  "USER_DEFINED" CHAR NOT NULL,
  view_type VARCHAR2(12 BYTE),
  model_name VARCHAR2(256 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);