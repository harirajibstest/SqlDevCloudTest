CREATE TABLE "TEST_VSTSRedgate".trsystem024 (
  shrt_user_id VARCHAR2(50 BYTE) NOT NULL,
  shrt_menu_id NUMBER(4) NOT NULL,
  shrt_icon_id NUMBER(3) NOT NULL,
  shrt_order_no NUMBER(3),
  CONSTRAINT trsystem024_pk PRIMARY KEY (shrt_user_id,shrt_menu_id)
);