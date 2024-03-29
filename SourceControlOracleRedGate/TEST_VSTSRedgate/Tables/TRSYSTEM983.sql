CREATE TABLE "TEST_VSTSRedgate".trsystem983 (
  userid VARCHAR2(50 BYTE),
  ason_date DATE,
  frwdtd NUMBER(15,4),
  frwmtd NUMBER(15,4),
  frwytd NUMBER(15,4),
  furdtd NUMBER(15,4),
  furmtd NUMBER(15,4),
  furytd NUMBER(15,4),
  optdtd NUMBER(15,4),
  optmtd NUMBER(15,4),
  optytd NUMBER(15,4),
  frwmtm NUMBER(15,4),
  furmtm NUMBER(15,4),
  optmtm NUMBER(15,4),
  deal_type NUMBER(8),
  hedgetrade NUMBER(8),
  companycode NUMBER(8),
  trader NUMBER(8),
  dealnumber VARCHAR2(25 BYTE),
  maturitydate DATE,
  currencycode NUMBER(8),
  counterparty NUMBER(8),
  executedate DATE,
  exchangerate NUMBER(15,6),
  dealbaseamount NUMBER(15,2),
  dealremarks VARCHAR2(512 BYTE),
  userreference VARCHAR2(50 BYTE),
  spotrate NUMBER(15,6),
  forwardrate NUMBER(15,6),
  marginrate NUMBER(15,6),
  locationcode NUMBER(8),
  cancelamount NUMBER(15,2),
  canceldate DATE,
  cancelrate NUMBER(15,6),
  buysellcode NUMBER(8),
  dealserial NUMBER,
  dealsubserial NUMBER,
  description VARCHAR2(30 BYTE),
  recorder NUMBER,
  processcomplete NUMBER(8),
  forcurrency NUMBER(8),
  expirydate DATE,
  profitloss NUMBER(15,2),
  cancelspot NUMBER(15,6),
  cancelforward NUMBER(15,6),
  cancelmargin NUMBER(15,6),
  brokercode NUMBER(8),
  premiumstatus NUMBER(8),
  premiumamount NUMBER(15,2),
  optiontype NUMBER(8),
  cancelpnlspot NUMBER(15,6),
  cancelpnlusd NUMBER(15,2),
  mtmrate NUMBER(15,6),
  deltavalue NUMBER(15,2),
  optvplinr NUMBER(15,2),
  optvplusd NUMBER(15,2),
  outstandingamount NUMBER(15,2),
  recordstatus NUMBER(8),
  confirmdate DATE,
  dealtimestamp VARCHAR2(50 BYTE),
  dealernmae VARCHAR2(50 BYTE),
  counterdealer VARCHAR2(50 BYTE),
  exchangecode VARCHAR2(50 BYTE),
  dealtype NUMBER(8),
  premiumvaluedate DATE,
  cconfirmdate DATE,
  crecordstatus NUMBER(8),
  cdealername VARCHAR2(50 BYTE),
  ccounterdealer VARCHAR2(50 BYTE),
  cedccharge NUMBER(15,2),
  ccashflowdate DATE,
  cpremiumstatus NUMBER(8),
  cpremiumamount NUMBER(15,2),
  exercisetype NUMBER(8),
  centerdby VARCHAR2(50 BYTE),
  enterdby VARCHAR2(50 BYTE),
  excersisetype NUMBER(8),
  presentvalueinr NUMBER(15,2),
  presentvalueusd NUMBER(15,2),
  premiumdolleramt NUMBER(15,2),
  transactiontype NUMBER(8),
  buycall NUMBER(15,6),
  sellcall NUMBER(15,6),
  sellput NUMBER(15,6),
  buyput NUMBER(15,6),
  premiumrate NUMBER(15,6),
  cpremiumrate NUMBER(15,6),
  rbirefrate NUMBER(15,6),
  dayonefrwd NUMBER(15,2),
  premiuminrateinseption NUMBER(15,6),
  premiuminratecancel NUMBER(15,6),
  spotusdrate NUMBER(15,6),
  frwdfinalmtm NUMBER(15,2),
  mtmspot NUMBER(15,6),
  mtmpremium NUMBER(15,6)
);