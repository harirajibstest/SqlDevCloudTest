CREATE TABLE "TEST_VSTSRedgate".dmrs_transformations (
  transformation_id VARCHAR2(70 BYTE) NOT NULL,
  transformation_ovid VARCHAR2(36 BYTE) NOT NULL,
  transformation_name VARCHAR2(256 BYTE) NOT NULL,
  transformation_task_id VARCHAR2(70 BYTE) NOT NULL,
  transformation_task_ovid VARCHAR2(36 BYTE) NOT NULL,
  transformation_task_name VARCHAR2(256 BYTE) NOT NULL,
  filter_condition VARCHAR2(4000 BYTE),
  join_condition VARCHAR2(4000 BYTE),
  "PRIMARY" CHAR,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);