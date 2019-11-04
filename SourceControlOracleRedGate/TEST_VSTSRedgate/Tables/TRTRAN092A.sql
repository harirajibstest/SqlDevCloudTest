CREATE TABLE "TEST_VSTSRedgate".trtran092a (
  irfs_irf_number VARCHAR2(25 BYTE) NOT NULL,
  irfs_serial_number VARCHAR2(25 BYTE) NOT NULL,
  irfs_settlement_date DATE,
  irfs_notional_amount NUMBER(15,2),
  irfs_lot_price NUMBER(15,6),
  irfs_user_remarks VARCHAR2(50 BYTE),
  irfs_create_date DATE,
  irfs_add_date DATE,
  irfs_entry_details XMLTYPE,
  irfs_time_stamp VARCHAR2(25 BYTE),
  irfs_record_status NUMBER(8),
  irfs_conversion_rate NUMBER(15,6),
  irfs_payoff_localamount NUMBER(15,2),
  irfs_payoff_amount NUMBER(15,2),
  irfs_payoff_type NUMBER(8),
  irfs_payoff_date DATE,
  CONSTRAINT trtran092a_pk PRIMARY KEY (irfs_irf_number,irfs_serial_number)
);