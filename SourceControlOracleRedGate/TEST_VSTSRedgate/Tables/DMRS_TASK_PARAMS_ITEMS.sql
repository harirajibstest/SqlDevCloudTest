CREATE TABLE "TEST_VSTSRedgate".dmrs_task_params_items (
  task_params_item_id VARCHAR2(70 BYTE) NOT NULL,
  task_params_item_ovid VARCHAR2(36 BYTE) NOT NULL,
  task_params_item_name VARCHAR2(256 BYTE) NOT NULL,
  task_params_id VARCHAR2(70 BYTE) NOT NULL,
  task_params_ovid VARCHAR2(36 BYTE) NOT NULL,
  task_params_name VARCHAR2(256 BYTE) NOT NULL,
  logical_type_id VARCHAR2(70 BYTE),
  logical_type_ovid VARCHAR2(36 BYTE),
  logical_type_name VARCHAR2(256 BYTE),
  task_params_item_type VARCHAR2(30 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);