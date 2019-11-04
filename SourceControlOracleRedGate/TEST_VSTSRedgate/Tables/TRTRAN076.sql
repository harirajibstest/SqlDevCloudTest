CREATE TABLE "TEST_VSTSRedgate".trtran076 (
  open_trade_date DATE NOT NULL,
  open_volume NUMBER(15,2),
  open_value NUMBER(15,2),
  open_spread_volume NUMBER(15,2),
  open_open_interest NUMBER(15,2),
  open_create_date DATE,
  open_add_date DATE,
  open_entry_details XMLTYPE,
  open_record_status NUMBER(8),
  CONSTRAINT trtran076_pk PRIMARY KEY (open_trade_date)
);