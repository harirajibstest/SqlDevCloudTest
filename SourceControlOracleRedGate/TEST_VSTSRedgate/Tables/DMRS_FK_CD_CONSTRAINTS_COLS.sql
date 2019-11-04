CREATE TABLE "TEST_VSTSRedgate".dmrs_fk_cd_constraints_cols (
  constraint_ovid VARCHAR2(36 BYTE) NOT NULL,
  column_ovid VARCHAR2(36 BYTE) NOT NULL,
  depend_as_mandatory VARCHAR2(1 BYTE),
  depend VARCHAR2(1 BYTE),
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);