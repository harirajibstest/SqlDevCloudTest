CREATE TABLE "TEST_VSTSRedgate".trsystem999c (
  grid_cursor_name VARCHAR2(50 BYTE) NOT NULL,
  grid_cursor_number NUMBER(4) NOT NULL,
  grid_column_name VARCHAR2(50 BYTE) NOT NULL,
  grid_column_type NUMBER(8),
  grid_display_name VARCHAR2(50 BYTE),
  grid_display_yn NUMBER(8),
  grid_column_width NUMBER(3),
  grid_aggregate_yn NUMBER(8),
  grid_aggregate_function VARCHAR2(10 BYTE),
  grid_editable_yn NUMBER(8),
  grid_decimal_scale NUMBER(5),
  grid_display_order NUMBER(3),
  CONSTRAINT trsystem999c_pk PRIMARY KEY (grid_cursor_name,grid_cursor_number,grid_column_name)
);