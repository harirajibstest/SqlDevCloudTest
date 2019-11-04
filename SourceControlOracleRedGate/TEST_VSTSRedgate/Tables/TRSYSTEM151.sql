CREATE TABLE "TEST_VSTSRedgate".trsystem151 (
  cmdl_company_code NUMBER(8) NOT NULL,
  cmdl_deal_number VARCHAR2(25 BYTE) NOT NULL,
  cmdl_user_reference VARCHAR2(25 BYTE),
  cmdl_execute_date DATE NOT NULL,
  cmdl_exchange_code NUMBER(8) NOT NULL,
  cmdl_counter_party NUMBER(8) NOT NULL,
  cmdl_currency_code NUMBER(8) NOT NULL,
  cmdl_exchange_rate NUMBER(15,6) NOT NULL,
  cmdl_contract_type NUMBER(8) NOT NULL,
  cmdl_hedge_trade NUMBER(8) NOT NULL,
  cmdl_buy_sell NUMBER(8) NOT NULL,
  cmdl_product_code NUMBER(8) NOT NULL,
  cmdl_local_bank NUMBER(8) NOT NULL,
  cmdl_lot_numbers NUMBER(5) NOT NULL,
  cmdl_product_quantity NUMBER(7) NOT NULL,
  cmdl_product_uom NUMBER(8) NOT NULL,
  cmdl_lot_price NUMBER(15,4) NOT NULL,
  cmdl_deal_amount NUMBER(15,2) NOT NULL,
  cmdl_deal_local NUMBER(15,2) NOT NULL,
  cmdl_margin_rate NUMBER(5,2) NOT NULL,
  cmdl_margin_amount NUMBER(15,2) NOT NULL,
  cmdl_brokerage_rate NUMBER(5,2) NOT NULL,
  cmdl_brokerage_amount NUMBER(15,2) NOT NULL,
  cmdl_service_tax NUMBER(15,2),
  cmdl_transaction_cost NUMBER(15,2),
  cmdl_other_charges NUMBER(15,2),
  cmdl_maturity_month NUMBER(6) NOT NULL,
  cmdl_maturity_date DATE NOT NULL,
  cmdl_spread_yn NUMBER(8) NOT NULL,
  cmdl_spread_deal VARCHAR2(25 BYTE),
  cmdl_cancel_deal VARCHAR2(25 BYTE),
  cmdl_delivery_yn NUMBER(8) NOT NULL,
  cmdl_delivery_date DATE,
  cmdl_delivery_qty NUMBER(7),
  cmdl_delivery_uom NUMBER(8),
  cmdl_receipt_number VARCHAR2(25 BYTE),
  cmdl_receipt_date DATE,
  cmdl_warehouse_code NUMBER(8),
  cmdl_user_id VARCHAR2(30 BYTE) NOT NULL,
  cmdl_dealer_remark VARCHAR2(1000 BYTE),
  cmdl_bo_remark VARCHAR2(1000 BYTE),
  cmdl_confirm_date DATE,
  cmdl_execute_time VARCHAR2(10 BYTE) NOT NULL,
  cmdl_time_stamp VARCHAR2(25 BYTE) NOT NULL,
  cmdl_process_complete NUMBER(8) NOT NULL,
  cmdl_complete_date DATE,
  cmdl_create_date DATE NOT NULL,
  cmdl_add_date DATE NOT NULL,
  cmdl_entry_detail XMLTYPE,
  cmdl_record_status NUMBER(8) NOT NULL,
  workdate DATE,
  datestamp VARCHAR2(25 BYTE),
  imagetype VARCHAR2(10 BYTE),
  entity VARCHAR2(30 BYTE),
  cmdl_init_code NUMBER(8),
  cmdl_backup_deal NUMBER(8)
);