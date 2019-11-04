CREATE TABLE "TEST_VSTSRedgate".trsystem968 (
  locl_data_name VARCHAR2(50 BYTE),
  locl_source_column VARCHAR2(50 BYTE),
  locl_destination_column VARCHAR2(50 BYTE),
  locl_pick_group NUMBER(3) DEFAULT 0,
  locl_tool_tip VARCHAR2(150 BYTE),
  locl_record_status NUMBER(8) DEFAULT 12400001,
  locl_column_id NUMBER(3) DEFAULT 1,
  locl_display_name VARCHAR2(100 BYTE),
  locl_data_type NUMBER(8) DEFAULT 90400001,
  locl_column_width NUMBER(3) DEFAULT 150,
  locl_column_editable NUMBER(8) DEFAULT 12400001
);
COMMENT ON COLUMN "TEST_VSTSRedgate".trsystem968.locl_tool_tip IS 'prefix ''Tooltip'' if in case serial number is 1';