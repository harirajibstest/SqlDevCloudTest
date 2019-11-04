CREATE TABLE "TEST_VSTSRedgate".dmrs_task_params (
  task_params_id VARCHAR2(70 BYTE) NOT NULL,
  task_params_ovid VARCHAR2(36 BYTE) NOT NULL,
  task_params_name VARCHAR2(256 BYTE) NOT NULL,
  transformation_task_id VARCHAR2(70 BYTE) NOT NULL,
  transformation_task_ovid VARCHAR2(36 BYTE) NOT NULL,
  transformation_task_name VARCHAR2(256 BYTE) NOT NULL,
  task_params_type VARCHAR2(30 BYTE),
  multiplicity VARCHAR2(30 BYTE),
  system_objective VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);