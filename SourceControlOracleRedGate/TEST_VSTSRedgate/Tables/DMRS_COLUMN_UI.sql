CREATE TABLE "TEST_VSTSRedgate".dmrs_column_ui (
  "LABEL" VARCHAR2(256 BYTE),
  format_mask VARCHAR2(50 BYTE),
  form_display_width NUMBER(4),
  form_maximum_width NUMBER(4),
  display_as VARCHAR2(30 BYTE),
  form_height NUMBER(4),
  displayed_on_forms CHAR,
  displayed_on_reports CHAR,
  read_only CHAR,
  help_text VARCHAR2(4000 BYTE),
  object_id VARCHAR2(70 BYTE) NOT NULL,
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  object_name VARCHAR2(256 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);