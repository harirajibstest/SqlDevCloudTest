CREATE TABLE "TEST_VSTSRedgate".trstaging011 (
  "EXCHANGE" VARCHAR2(50 BYTE),
  party_code VARCHAR2(50 BYTE),
  party_name VARCHAR2(100 BYTE),
  symbol VARCHAR2(50 BYTE),
  expiry VARCHAR2(50 BYTE),
  option_type VARCHAR2(50 BYTE),
  strike_price VARCHAR2(50 BYTE),
  buy_qty VARCHAR2(50 BYTE),
  buy_rate VARCHAR2(30 BYTE),
  buy_amt VARCHAR2(30 BYTE),
  sell_qty VARCHAR2(30 BYTE),
  sell_rate VARCHAR2(30 BYTE),
  sell_amt VARCHAR2(30 BYTE),
  net_qty VARCHAR2(30 BYTE),
  recordstatus NUMBER(8),
  entrydate DATE,
  brokername VARCHAR2(20 BYTE)
);