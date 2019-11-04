CREATE TABLE "TEST_VSTSRedgate".dmrs_transformation_packages (
  transformation_package_id VARCHAR2(70 BYTE) NOT NULL,
  transformation_package_ovid VARCHAR2(36 BYTE) NOT NULL,
  transformation_package_name VARCHAR2(256 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  system_objective VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);