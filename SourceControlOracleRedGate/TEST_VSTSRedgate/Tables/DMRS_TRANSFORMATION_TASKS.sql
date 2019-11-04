CREATE TABLE "TEST_VSTSRedgate".dmrs_transformation_tasks (
  transformation_task_id VARCHAR2(70 BYTE) NOT NULL,
  transformation_task_ovid VARCHAR2(36 BYTE) NOT NULL,
  transformation_task_name VARCHAR2(256 BYTE) NOT NULL,
  transformation_package_id VARCHAR2(70 BYTE) NOT NULL,
  transformation_package_ovid VARCHAR2(36 BYTE) NOT NULL,
  transformation_package_name VARCHAR2(256 BYTE) NOT NULL,
  process_id VARCHAR2(70 BYTE),
  process_ovid VARCHAR2(36 BYTE),
  process_name VARCHAR2(256 BYTE),
  top_level CHAR,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);