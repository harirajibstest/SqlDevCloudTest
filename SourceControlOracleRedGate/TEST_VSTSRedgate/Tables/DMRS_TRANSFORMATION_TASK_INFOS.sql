CREATE TABLE "TEST_VSTSRedgate".dmrs_transformation_task_infos (
  transformation_task_id VARCHAR2(70 BYTE) NOT NULL,
  transformation_task_ovid VARCHAR2(36 BYTE) NOT NULL,
  transformation_task_name VARCHAR2(256 BYTE) NOT NULL,
  info_store_id VARCHAR2(70 BYTE) NOT NULL,
  info_store_ovid VARCHAR2(36 BYTE) NOT NULL,
  info_store_name VARCHAR2(256 BYTE) NOT NULL,
  source_target_flag CHAR,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);