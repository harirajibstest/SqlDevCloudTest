CREATE TABLE "TEST_VSTSRedgate".trstaging011b (
  message_type VARCHAR2(4 BYTE),
  deal_type VARCHAR2(100 BYTE),
  side VARCHAR2(100 BYTE),
  product VARCHAR2(100 BYTE),
  status VARCHAR2(100 BYTE),
  revision_version VARCHAR2(100 BYTE),
  trade_id VARCHAR2(100 BYTE),
  block_id VARCHAR2(100 BYTE),
  trader_id VARCHAR2(100 BYTE),
  trader_name VARCHAR2(100 BYTE),
  counterparty_id VARCHAR2(100 BYTE),
  counterparty_trader_name VARCHAR2(100 BYTE),
  date_of_deal VARCHAR2(100 BYTE),
  time_of_deal VARCHAR2(100 BYTE),
  trade_date VARCHAR2(100 BYTE),
  date_confirmed VARCHAR2(100 BYTE),
  time_confirmed VARCHAR2(100 BYTE),
  counterparty_dealing_code VARCHAR2(100 BYTE),
  counterparty_name VARCHAR2(100 BYTE),
  user_identifier_1 VARCHAR2(100 BYTE),
  user_identifier_2 VARCHAR2(100 BYTE),
  user_identifier_3 VARCHAR2(100 BYTE),
  user_identifier_4 VARCHAR2(100 BYTE),
  prime_broker_deal_code VARCHAR2(100 BYTE),
  prime_broker_name VARCHAR2(100 BYTE),
  currency_1 VARCHAR2(100 BYTE),
  currency_2 VARCHAR2(100 BYTE),
  amount_dealt VARCHAR2(100 BYTE),
  dealt_currency VARCHAR2(100 BYTE),
  counter_amount VARCHAR2(100 BYTE),
  counter_currency VARCHAR2(100 BYTE),
  forward_points_near VARCHAR2(30 BYTE),
  far_amount_dealt VARCHAR2(100 BYTE),
  far_currency_dealt VARCHAR2(100 BYTE),
  far_counter_amount VARCHAR2(100 BYTE),
  far_counte_currency VARCHAR2(100 BYTE),
  forward_points_far VARCHAR2(100 BYTE),
  spot_basis_rate VARCHAR2(100 BYTE),
  deposit_rate VARCHAR2(100 BYTE),
  day_count VARCHAR2(100 BYTE),
  rollover_transaction_indicator VARCHAR2(100 BYTE),
  volume_of_interest VARCHAR2(100 BYTE),
  exchange_rate_period_1 VARCHAR2(100 BYTE),
  value_date_period_1 VARCHAR2(100 BYTE),
  tenor_period_1 VARCHAR2(4 BYTE),
  fixing_date_period_1 VARCHAR2(100 BYTE),
  fixing_source_period_1 VARCHAR2(100 BYTE),
  settle_currency VARCHAR2(3 BYTE),
  swap_rate VARCHAR2(100 BYTE),
  exchange_rate_period_2 VARCHAR2(100 BYTE),
  value_date_period2 VARCHAR2(100 BYTE),
  tenor_period_2 VARCHAR2(100 BYTE),
  fixing_date_period_2 VARCHAR2(100 BYTE),
  fixing_source_period_2 VARCHAR2(100 BYTE),
  split_tenor_currency_1 VARCHAR2(100 BYTE),
  split_valuedate_currency_1 VARCHAR2(100 BYTE),
  split_tenorcurrency_2 VARCHAR2(100 BYTE),
  split_valuedate_currency2 VARCHAR2(100 BYTE),
  comment_text VARCHAR2(100 BYTE),
  note_name_1 VARCHAR2(100 BYTE),
  note_text_1 VARCHAR2(100 BYTE),
  note_name_2 VARCHAR2(100 BYTE),
  note_text_2 VARCHAR2(100 BYTE),
  note_name_3 VARCHAR2(100 BYTE),
  note_text_3 VARCHAR2(100 BYTE),
  note_name_4 VARCHAR2(100 BYTE),
  note_text_4 VARCHAR2(100 BYTE),
  note_name_5 VARCHAR2(100 BYTE),
  note_text_5 VARCHAR2(100 BYTE),
  competing_quote_1 VARCHAR2(100 BYTE),
  competing_quotedeal_code_1 VARCHAR2(100 BYTE),
  competing_quote_2 VARCHAR2(100 BYTE),
  competing_quotedeal_code2 VARCHAR2(100 BYTE),
  competing_quote3 VARCHAR2(100 BYTE),
  competing_quotedeal_code3 VARCHAR2(100 BYTE),
  competing_quote4 VARCHAR2(100 BYTE),
  competing_quotedeal_code4 VARCHAR2(100 BYTE),
  competing_quote5 VARCHAR2(100 BYTE),
  competing_quotedea_code5 VARCHAR2(100 BYTE),
  portfolio VARCHAR2(2 BYTE),
  allocation_account VARCHAR2(100 BYTE),
  allocation_description VARCHAR2(100 BYTE),
  allocation_custodian VARCHAR2(100 BYTE),
  prime_broker_name2 VARCHAR2(100 BYTE),
  reference_spotrate VARCHAR2(100 BYTE),
  reference_rate_period1 VARCHAR2(100 BYTE),
  reference_rateperiod_2 VARCHAR2(100 BYTE),
  pay_currency VARCHAR2(100 BYTE),
  pay_swift_code VARCHAR2(14 BYTE),
  pay_account_number VARCHAR2(100 BYTE),
  pay_bank VARCHAR2(100 BYTE),
  pay_branch VARCHAR2(15 BYTE),
  pay_beneficiary VARCHAR2(14 BYTE),
  pay_special_instructions VARCHAR2(1100 BYTE),
  receiving_currency VARCHAR2(100 BYTE),
  receiving_swift_code VARCHAR2(100 BYTE),
  receiving_account_number VARCHAR2(100 BYTE),
  receiving_bank VARCHAR2(100 BYTE),
  receiving_branch VARCHAR2(100 BYTE),
  receiving_beneficiary VARCHAR2(100 BYTE),
  receiving_special_instructions VARCHAR2(100 BYTE),
  spot_rate_mid_point VARCHAR2(100 BYTE),
  rate_nearleg_midpoint VARCHAR2(100 BYTE),
  nearleg_forwardpoint_midpoint VARCHAR2(100 BYTE),
  allinrate_farleg_midpoint VARCHAR2(100 BYTE),
  farleg_forwardpoint_midpoint VARCHAR2(100 BYTE),
  usi_uti_namespace VARCHAR2(100 BYTE),
  usi_uti_identifier VARCHAR2(100 BYTE),
  usi_uti_identifier_nearleg VARCHAR2(100 BYTE),
  delivery_date VARCHAR2(100 BYTE),
  banknote_ratetype VARCHAR2(100 BYTE),
  commission VARCHAR2(100 BYTE),
  execution_venue VARCHAR2(100 BYTE),
  broker_id VARCHAR2(100 BYTE),
  broker_deal_code VARCHAR2(100 BYTE),
  "GROUP_ID" VARCHAR2(100 BYTE),
  group_type VARCHAR2(100 BYTE),
  trademethod VARCHAR2(100 BYTE),
  filename VARCHAR2(500 BYTE)
);