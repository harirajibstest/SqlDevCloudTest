CREATE TABLE "TEST_VSTSRedgate".trsystem036 (
  exld_report_id VARCHAR2(30 BYTE) NOT NULL,
  exld_field_name VARCHAR2(100 BYTE) NOT NULL,
  exld_column_index NUMBER(3),
  exld_visible NUMBER(8) DEFAULT 12400001,
  exld_show_desc NUMBER(8) DEFAULT 12400002,
  exld_pick_key_group NUMBER(8),
  exld_data_type VARCHAR2(50 BYTE)
);