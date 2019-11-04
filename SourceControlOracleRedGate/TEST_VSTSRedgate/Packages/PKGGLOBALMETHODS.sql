CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGGLOBALMETHODS" 
-- Author: T M Manjunath
-- Created On: 11/03/2007
-- Last Modified on: 23/03/2007

  AS
--  Constants

--  Pickup Types62
    INTEGRATE_WITH_TF       CONSTANT char(1)  :='N';
    PICKUPSYSTEMTYPE        CONSTANT number(8) := 10100001;
    PICKUPUSERTYPE          CONSTANT number(8) := 10100002;
    PICKUPMASTERTYPE        CONSTANT number(8) := 10100003;

--  Transaction Statuses
    STATUSENTRY             CONSTANT number(8) := 10200001;
    STATUSAPREUTHORIZATION  CONSTANT number(8) := 10200002;
    STATUSAUTHORIZED        CONSTANT number(8) := 10200003;
    STATUSUPDATED           CONSTANT number(8) := 10200004;
    STATUSINACTIVE          CONSTANT number(8) := 10200005;
    STATUSDELETED           CONSTANT number(8) := 10200006;
    STATUSCOMPLETED         CONSTANT number(8) := 10200010;
    STATUSPRECANCEL         CONSTANT number(8) := 10200011;
    STATUSPOSTCANCEL        CONSTANT number(8) := 10200012;
    STATUSPROCESSOVER       CONSTANT number(8) := 10200099;
--  Status for transactions
--  Level - 2
    STATUSL2ENTRY           CONSTANT number(8) := 10200021;
    STATUSL2UPDATED         CONSTANT number(8) := 10200022;
    STATUSL2DELETED         CONSTANT number(8) := 10200023;
    STATUSL2CONFIRMED       CONSTANT number(8) := 10200024;
--  Level - 3
    STATUSL3ENTRY           CONSTANT number(8) := 10200031;
    STATUSL3UPDATED         CONSTANT number(8) := 10200032;
    STATUSL3DELETED         CONSTANT number(8) := 10200033;
    STATUSL3CONFIRMED       CONSTANT number(8) := 10200034;
--  Level - 4
    STATUSL4ENTRY           CONSTANT number(8) := 10200041;
    STATUSL4UPDATED         CONSTANT number(8) := 10200042;
    STATUSL4DELETED         CONSTANT number(8) := 10200043;
    STATUSL4CONFIRMED       CONSTANT number(8) := 10200044;

--  User Security Policies
    POLICYUSERID            CONSTANT number(8) := 10400001;
    POLICYTERMINAL          CONSTANT number(8) := 10400002;
    POLICYDAYTIME           CONSTANT number(8) := 10400003;
    POLICYSUSPEND           CONSTANT number(8) := 10400004;
    POLICYLOGIN             CONSTANT number(8) := 10400005;
    POLICYPASSWORD          CONSTANT number(8) := 10400006;

--  System Actions
    SYSMOVESERIAL           CONSTANT number(8) := 10600001;
    SYSMOVETODAY            CONSTANT number(8) := 10600002;
    SYSMOVESYSDATE          CONSTANT number(8) := 10600003;
    SYSMOVECOCODE           CONSTANT number(8) := 10600004;
    SYSMOVEDETAIL           CONSTANT number(8) := 10600005;
    SYSENTRYCODE            CONSTANT number(8) := 10600006;
    SYSUPDATECODE           CONSTANT number(8) := 10600007;
    SYSDELETECODE           CONSTANT number(8) := 10600008;
    SYSCONFIRMCODE          CONSTANT number(8) := 10600009;
    SYSPICKPROCESS          CONSTANT number(8) := 10600010;
    SYSINCREMENTKEY         CONSTANT number(8) := 10600011;
    SYSPRECONFIRM           CONSTANT number(8) := 10600012;
    SYSCURRENTAC            CONSTANT number(8) := 10600013;
    SYSPACKINGCREDIT        CONSTANT number(8) := 10600014;
    SYSBUYERSCREDIT         CONSTANT number(8) := 10600015;
    SYSUPDATESTATUS         CONSTANT number(8) := 10600016;
    SYSADDSERIAL            CONSTANT number(8) := 10600021;
    SYSADDDETAIL            CONSTANT number(8) := 10600022;
    SYSBCRNUMBER            CONSTANT number(8) := 10600038;
    SYSDEALNUMBER           CONSTANT number(8) := 10600039;
    SYSTRADENUMBER          CONSTANT number(8) := 10600040;
    SYSRISKNUMBER           CONSTANT number(8) := 10600041;
    SYSLOANNUMBER           CONSTANT number(8) := 10600042;
    SYSREMINDERNUMBER       CONSTANT number(8) := 10600043;
    SYSVOUCHERNUMBER        CONSTANT number(8) := 10600044;
    SYSDYNAMICREPORTID      CONSTANT number(8) := 10600045;
    SYSREMINDERID           CONSTANT number(8) := 10600046;
    SYSPUTTIMESTAMP         CONSTANT number(8) := 10600051;
    SYSOLDVALUE             CONSTANT number(8) := 10600098;
    SYSUSERINPUT            CONSTANT number(8) := 10600099;
    SYSFDNUMBER             CONSTANT number(8) := 10600052;
    SYSPURCHASE             CONSTANT number(8) := 10600053;
    SYSREMITTANCENUMBER     CONSTANT number(8) := 10600054;

    SYSMUTUALFUNDREFERENCE  CONSTANT number(8) := 10600055;
    SYSMUTUALFUNDREDEMPTOIN CONSTANT NUMBER(8) := 10600056;
    SYSBONDDEBENTUREPURCHASE CONSTANT number(8) := 10600057;

    SYSCPBDEALNUMBER        CONSTANT NUMBER(8) := 10600050;  
  
    SYSFUTURENUMBER         CONSTANT NUMBER(8) :=10600060;
    SYSFXGO                 CONSTANT NUMBER(8) :=10600061;
    SYSEMAIL                CONSTANT NUMBER(8) :=10600062;

    SYSMMDEALNUMBER         CONSTANT number(8) := 10600047;
    SYSCOMMDITYDEAL         CONSTANT number(8) := 10600048;
    SYSCOMMRISKNUMBER       CONSTANT number(8) := 10600049;
    SYSBANKCHARGE           CONSTANT number(8) := 10600160;
    SYSTERMLOAN             CONSTANT number(8) := 10600107;

 

    SYSEXPORTADJUST         CONSTANT number(8) := 10600201;
    SYSDEALADJUST           CONSTANT number(8) := 10600202;
    SYSHOLDINGRATE          CONSTANT number(8) := 10600203;
    SYSCANCELDEAL           CONSTANT number(8) := 10600204;
    SYSDEALDELIVERY         CONSTANT number(8) := 10600205;
    SYSLOANCONNECT          CONSTANT number(8) := 10600206;
    SYSRISKGENERATE         CONSTANT number(8) := 10600207;
    SYSRATECALCULATE        CONSTANT number(8) := 10600208;
    SYSHEDGERISK            CONSTANT number(8) := 10600209;
    SYSVOUCHERCA            CONSTANT number(8) := 10600210;
    SYSBCRCONNECT           CONSTANT number(8) := 10600211;
    SYSBCRFDLIEN            CONSTANT number(8) := 10600212;
    SYSPURCONNECT           CONSTANT number(8) := 10600213;
    SYSRELATION             CONSTANT number(8) := 10600214;
    SYSRATECALCULATE1       CONSTANT number(8) := 10600215;
    SYSAANDLPOSITION        CONSTANT number(8) := 10600216;
    SYSFUTUREMTMUPLOAD      CONSTANT number(8) := 10600217;
    SYSCASHDEAL             CONSTANT number(8) := 10600218;
    SYSCONTRACTSHCEDULE     CONSTANT number(8):=  10600219;
    SYSCONTRACTUPLOAD       CONSTANT number(8):=  10600220;
    

    SYSSTRESSINSERTSUB      CONSTANT number(8) := 10600221;
    Sysstressanalysis       Constant Number(8) := 10600222;
    
    SYSPURCONCANCEL         CONSTANT number(8):=  10600228;    ---10600223;

    SYSTDSRATE              CONSTANT number(8) := 10600223;
    SYSFDRATE               CONSTANT number(8) := 10600224;

    SYSFDCOMPLETESTATUS     CONSTANT number(8) := 10600225;
    SYSMUTUALCOMPLETESTATUS CONSTANT number(8) := 10600226;

    SYSMUTUALSWITCHIN       CONSTANT number(8) := 10600227;
    SYSRATEUPLOAD           CONSTANT number(8) := 10600229;
    SYSDELETEFUTUREDATA     CONSTANT NUMBER(8) := 10600230;

    SYSHEDGELINKINGCANCEL   CONSTANT number(8) := 10600231;
    SYSFORWARDROLLOVERPROCESS      CONSTANT number(8) := 10600232;
    SYSFUTUREROLLOVERPROCESS      CONSTANT number(8) := 10600233;
-------Commodity Module    
    SYSCOMMDEALREVERSAL     CONSTANT number(8) := 10600301;
    SYSFUTURETRADEDEAL      CONSTANT number(8) := 10600401;
    SYSFUTUREREVERSAL       CONSTANT Number(8) := 10600402;
    SYSOPTIONTRADEDEAL      CONSTANT Number(8) := 10600403;
    SYSOPTIONMATURITY       CONSTANT Number(8) := 10600404;
    SYSOPTIONCANCELDEAL     CONSTANT number(8) := 10600405;
    SYSLINKBATCHNO          CONSTANT Number(8) := 10600406;
    SYSLINKUPDATETABLES     CONSTANT number(8) := 10600407;
    SYSUPDATEDEALNO         CONSTANT number(8) := 10600408; -- for MTM Stmt upload
    SYSSERIALBANKSTAT       CONSTANT number(8) := 10600409; -- for MTM Stmt upload
    SYSUPDATEORDINVLINK     CONSTANT number(8) := 10600410; -- for Order-Invoice Link
    SYSEXCHMTMUPDATE        CONSTANT number(8) := 10600411;
    SYSUSERUPDATE           CONSTANT NUMBER(8) := 10600412;
    SYSCOMHEDGELINKING      CONSTANT NUMBER(8) := 10600413;
    SYSCOMPANYUPDATE        CONSTANT NUMBER(8) := 10600414;    
    Sysscanfiles            Constant Number(8) := 10600415; 
    SYSRBIREFRATE           Constant Number(8) := 10600416;    
    SYSBANKCHARGEINSERT     CONSTANT NUMBER(8) := 10600181;
--- FRA Sys numbers
    SYSFRANUMBER            CONSTANT number(8) := 10600501;
    SYSIRSNUMBER            CONSTANT number(8) := 10600502;
    SYSIRSPOPULATE          CONSTANT number(8) := 10600503;
    SYSIRFNUMBER            CONSTANT number(8) := 10600504;
    SYSIROPOPULATE          CONSTANT number(8) := 10600505;
    SYSIRONUMBER            CONSTANT number(8) := 10600506;
    SYSCCIRSNUMBER          CONSTANT number(8) := 10600507;
    SYSCCIRSPOPULATE        CONSTANT number(8) := 10600508;
    SYSCCIRSSETTLE          CONSTANT NUMBER(8) := 10600509;    
    SYSPRODUCTMATURITY      CONSTANT NUMBER(8) := 10600510;   
    SYSEXPOSURESETTLEMENT   CONSTANT NUMBER(8) := 10600511;   
    
        -- Stress Anaysis (Arjun) 250614



--  Serial Number Generation
    SGENOCONCAT             CONSTANT number(8) := 10700001;
    SGENCONCATDAY           CONSTANT number(8) := 10700002;
    SGENCONCTMONTH          CONSTANT number(8) := 10700003;
    SGENCONCATYEAR          CONSTANT number(8) := 10700004;
    SGENCONCATFIN           CONSTANT number(8) := 10700005;
--  Serial Number Reset
    SRESETDAILY             CONSTANT number(8) := 10800001;
    SRESETMONTHLY           CONSTANT number(8) := 10800002;
    SRESETCALENDAR          CONSTANT number(8) := 10800003;
    SRESETFINANCE           CONSTANT number(8) := 10800004;
    SRESETNEVER             CONSTANT number(8) := 10800005;
--  Serial Number Types
    SERIALFD                CONSTANT number(8) := 10900010;
    SERIALBCR               CONSTANT number(8) := 10900011;
    SERIALPURCHASE          CONSTANT number(8) := 10900012;
    SERIALDEAL              CONSTANT number(8) := 10900014;
    SERIALTRADE             CONSTANT number(8) := 10900015;
    SERIALRISK              CONSTANT number(8) := 10900016;
    SERIALLOAN              CONSTANT number(8) := 10900017;
    SERIALREMINDER          CONSTANT number(8) := 10900018;
    SERIALDAYLOG            CONSTANT number(8) := 10900019;
    SERIALAUDIT             CONSTANT number(8) := 10900020;
    SERIALCURRENT           CONSTANT number(8) := 10900021;
    SERIALDYNAMICREPORT     CONSTANT number(8) := 10900022;

    SERIALMMDEAL            CONSTANT number(8) := 10900023;

    SERIALCOMMODITYDEAL     CONSTANT number(8) := 10900024;
    SERIALCOMMRISK          CONSTANT number(8) := 10900025;

    SERIALRISKSERIAL        CONSTANT number(8) := 10900026;

    SERIALFUTURETRADE       CONSTANT number(8) := 10900027; --for currency future deals
    SERIALOPTIONTRADE       CONSTANT number(8) := 10900028; --for currency option deals

    SERIALLINKBATCHNO       CONSTANT number(8) := 10900029;
    SERIALBANKSTAT          CONSTANT number(8) := 10900030; -- for MTM Stmt upload
    SERIALNSESTAT           CONSTANT number(8) := 10900031; -- for NSE rate upload
    SERIALOPTIONPRODUCT     CONSTANT number(8) := 10900032; --abhijit uploaded for opt prod.
    SERIALREMITTANCE        CONSTANT number(8) := 10900033;
    SERIALCONTRACTSCHEDULE  CONSTANT number(8) := 10900034;--Abhijit added for excel upload
    SERIALSTRESS            CONSTANT number(8) := 10900035; --Stress Analysis (Arjun) 250614

    SERIALMUTUALFUND        CONSTANT NUMBER(8) := 10900036; -- MUTUAL FUND TRANSACTION

    SERIALMUTUALFUNDREDEMPTION CONSTANT NUMBER(8) := 10900037;
    SERIALBONDDEBENTUREPUR CONSTANT NUMBER(8)     := 10900038;    
    SERIALCPB               CONSTANT NUMBER(8) := 10900039;
    SERIALFRWDLINKBATCHNO   CONSTANT NUMBER(8) := 10900040;
    SERIALFUTURENUMBER  CONSTANT NUMBER(8) :=10900041;
    SERIALSTAFUTURE     CONSTANT NUMBER(8) :=10900042;
    SERIALFXGO                 CONSTANT NUMBER(8) :=10900043;
    SERIALEMAIL                CONSTANT NUMBER(8) :=10900044;
    SERIALSCANIMAGES           CONSTANT number(8) :=10900045;
    SEARIALCHARGE              CONSTANT number(8) := 10900055;
    -- FORWARD ROLLOVER
     SERIALFORWARDROLLOVER      CONSTANT NUMBER(8) := 10900047;
    SERIALDELIVERYBATCHNO   CONSTANT NUMBER(8) := 10900048;
    ---IRS  
    SERIALFRANUMBER         CONSTANT number(8) := 10900501;
    SERIALIRSNUMBER         CONSTANT number(8) := 10900502;  
    SERIALIRFNUMBER         CONSTANT number(8) := 10900503; 
    SERIALIRONUMBER         CONSTANT number(8) := 10900504; 
    SERIALCCIRNUMBER        CONSTANT number(8) := 10900505; 
    
--  Options
    OPTIONYES               CONSTANT number(8) := 12400001;
    OPTIONNO                CONSTANT number(8) := 12400002;
--  Dealers
    SUBDEALER               CONSTANT number(8) := 14200002;
    CHIEFDEALER             CONSTANT number(8) := 14200006;
    DATAENTRY               CONSTANT number(8) := 14200013;
    CONFIRMUSERS            CONSTANT number(8) := 14200014;
    SYSADMIN                CONSTANT number(8) := 14200012;


--  Voucher Credit
    TRANSACTIONCREDIT       CONSTANT number(8) := 14600001;
    TRANSACTIONDEBIT        CONSTANT number(8) := 14600002;

--  Risk Types
    RISKGROSSCURRENCY	      CONSTANT number(8) := 21000001;
    RISKNETCURRENCY	        CONSTANT number(8) := 21000002;
    RISKDEALLIMIT	          CONSTANT number(8) := 21000003;
    RISKOVERNIGHT	          CONSTANT number(8) := 21000004;
    RISKDAYLIGHT	          CONSTANT number(8) := 21000005;
    RISKCOUNTERPARTY	      CONSTANT number(8) := 21000006;
    RISKSTOPLOSSDAILY       CONSTANT number(8) := 21000011;
    RISKSTOPLOSSMTHLY       CONSTANT number(8) := 21000012;
    RISKSTOPLOSSQTRLY       CONSTANT number(8) := 21000013;
    RISKSTOPLOSSYERLY       CONSTANT number(8) := 21000014;
    RISKSTOPLOSSDEAL        CONSTANT number(8) := 21000015;
    RISKSTOPLOSSDAY         CONSTANT number(8) := 21000016;
    RISKHEDGESTOPLOSS       CONSTANT number(8) := 21000017;
    RISKGAPALL		          CONSTANT number(8) := 21000020;
    RISKGAPSPOT		          CONSTANT number(8) := 21000021;
    RISKGAPFORWARD1	        CONSTANT number(8) := 21000022;
    RISKGAPFORWARD2	        CONSTANT number(8) := 21000023;
    RISKGAPFORWARD3	        CONSTANT number(8) := 21000024;
    RISKGAPFORWARD4	        CONSTANT number(8) := 21000025;
    RISKGAPFORWARD5	        CONSTANT number(8) := 21000026;
    RISKGAPFORWARD6	        CONSTANT number(8) := 21000027;
    RISKGAPFORWARD7	        CONSTANT number(8) := 21000028;
    RISKGAPFORWARD8	        CONSTANT number(8) := 21000029;
    RISKGAPFORWARD9	        CONSTANT number(8) := 21000030;
    RISKGAPFORWARD10        CONSTANT number(8) := 21000031;
    RISKGAPFORWARD11        CONSTANT number(8) := 21000032;
    RISKGAPFORWARD12        CONSTANT number(8) := 21000033;
    RISKTAKEPROFIT          CONSTANT number(8) := 21000034;
----Commodity Risk
    CRISKGROSSCURRENCY	    CONSTANT number(8) := 21000201;
    CRISKNETCURRENCY	      CONSTANT number(8) := 21000202;
    CRISKDEALLIMIT	        CONSTANT number(8) := 21000203;
    CRISKSTOPLOSSDAILY      CONSTANT number(8) := 21000211;
    CRISKSTOPLOSSMTHLY      CONSTANT number(8) := 21000212;
    CRISKSTOPLOSSQTRLY      CONSTANT number(8) := 21000213;
    CRISKSTOPLOSSYERLY      CONSTANT number(8) := 21000214;
    CRISKGAPSPOT		        CONSTANT number(8) := 21000221;
    CRISKGAPFORWARD1	      CONSTANT number(8) := 21000222;
    CRISKGAPFORWARD2	      CONSTANT number(8) := 21000223;
    CRISKGAPFORWARD3	      CONSTANT number(8) := 21000224;
    CRISKGAPFORWARD4	      CONSTANT number(8) := 21000225;
    CRISKGAPFORWARD5	      CONSTANT number(8) := 21000226;
    CRISKGAPFORWARD6	      CONSTANT number(8) := 21000227;
    CRISKGAPFORWARD7	      CONSTANT number(8) := 21000228;
    CRISKGAPFORWARD8	      CONSTANT number(8) := 21000229;
    CRISKGAPFORWARD9	      CONSTANT number(8) := 21000230;
    CRISKGAPFORWARD10       CONSTANT number(8) := 21000231;
    CRISKGAPFORWARD11       CONSTANT number(8) := 21000232;
    CRISKGAPFORWARD12       CONSTANT number(8) := 21000233;



--  FCY Loan Reason Codes
    REASONIMPORT            CONSTANT number(8) := 23500001;
    REASONEXPORT            CONSTANT number(8) := 23500002;
    REASONOTHERS            CONSTANT number(8) := 23500003;
--  Foreign Currency Loans
    LOANBUYERSCREDIT        CONSTANT number(8) := 23600001;
    LOANPCFC                CONSTANT number(8) := 23600002;
    LOANPSCFC               CONSTANT number(8) := 23600003;
    LOANBCCLOSER            CONSTANT number(8) := 23600004;
    LOANTERMLOAN            CONSTANT number(8) := 23600005;

--  Current Record Type
    RECPROCEEDS             CONSTANT number(8) := 23800001;
    RECCURRENT              CONSTANT number(8) := 23800002;

--  Voucher Events
    EVENTPURCHASE           CONSTANT number(8) := 24800001;
    EVENTSALE               CONSTANT number(8) := 24800002;
    EVENTPURREVERSAL        CONSTANT number(8) := 24800003;
    EVENTSALREVERSAL        CONSTANT number(8) := 24800004;
    EVENTPURROLLOVER        CONSTANT number(8) := 24800005;
    EVENTSALROLLOVER        CONSTANT number(8) := 24800006;
    EVENTCOMMDAILYPL        CONSTANT number(8) := 24800007;
    EVENTOPTIONSPL          CONSTANT number(8) := 24800008;

    EVENTFUTUREPL           CONSTANT number(8) := 24800009;

    EVENTMMDEAL             CONSTANT number(8) := 24800011;
    EVENTMMREDEEM           CONSTANT number(8) := 24800012;

    EVENTMUTUALFUND         CONSTANT number(8) := 24800033;
    EVENTMUTUALFUNDREDEM    CONSTANT number(8) := 24800037;
    EVENTMUTUALFUNDSWITCH   CONSTANT number(8) := 24800038;

    EVENTFIXED              CONSTANT number(8) := 24800030;
    EVENTFDRENEW            CONSTANT number(8) := 24800032;
    EVENTFIXEDACCRUAL       CONSTANT number(8) := 24800031;
    EVENTFIXEDCLOSURE       CONSTANT number(8) := 24800036;


--    EVENTMANUAL             CONSTANT number(8) := 24800099;
    EVENTMISCELLANEOUS      CONSTANT number(8) := 24800099;
    EVENTMANUAL             CONSTANT number(8) := 24899999;

--  Account Heads
    ACFCYPURCHASE           CONSTANT number(8) := 24900001;
    ACFCYSALE               CONSTANT number(8) := 24900002;
    ACINRPURCHASE           CONSTANT number(8) := 24900003;
    ACINRSALE               CONSTANT number(8) := 24900004;
    ACEXCHANGE              CONSTANT number(8) := 24900061;
    ACINTERESTACCRUDE       Constant number(8) := 24900073;
    ACINTERESTONFD          CONSTANT number(8) := 24900074;
    ACTDS                   CONSTANT number(8) := 24900071;
    ACTDSSUR                CONSTANT number(8) := 24900072;


    ACINTINCOME             CONSTANT number(8) := 24900062;
    ACINTEXPENSE            CONSTANT number(8) := 24900063;
    ACPREMIUMAC             CONSTANT number(8) := 24900064;

--  Deal Category
    SWAPDEAL                CONSTANT number(8) := 25200001;
    OUTRIGHTDEAL            CONSTANT number(8) := 25200002;

--  Deal Type
    PURCHASEDEAL            CONSTANT number(8) := 25300001;
    SALEDEAL                CONSTANT number(8) := 25300002;
--Maturity Types
    CASH                    CONSTANT number(8) := 25400001;
    TOM                     CONSTANT number(8) := 25400002;
    SPOT                    CONSTANT number(8) := 25400003;
    FORWARDFIXED            CONSTANT number(8) := 25400004;
    FORWARDOPTION           CONSTANT number(8) := 25400005;
    OTHER                   CONSTANT number(8) := 25400006;

-- DaysTypes
    DAYS                    CONSTANT number(8) := 25500001;
    WEEKS                   CONSTANT number(8) := 25500002;
    MONTHS                  CONSTANT number(8) := 25500003;
    YEARS                   CONSTANT number(8) := 25500004;

--  Reversal Type
    BILLREALIZE             CONSTANT number(8) := 25800001;
    BILLCOLLECTION          CONSTANT number(8) := 25800002;
    BILLPURCHASE            CONSTANT number(8) := 25800003;
    BILLEEFC                CONSTANT number(8) := 25800004;
    BILLOVERDUE             CONSTANT number(8) := 25800005;
    BILLEXPORTCANCEL        CONSTANT number(8) := 25800006;
    BILLEXPORTORDER         CONSTANT number(8) := 25800009;
    BILLINWARDREMIT         CONSTANT number(8) := 25800011;
    BILLIMPORTCOL           CONSTANT number(8) := 25800051;
    BILLIMPORTREL           CONSTANT number(8) := 25800052;
    BILLIMPORTCANCEL        CONSTANT number(8) := 25800053;
    BILLIMPORTORDER         CONSTANT number(8) := 25800054;
    BILLPURCHASEORDER       CONSTANT number(8) := 25800055;
    BILLOUTWARDREMIT        CONSTANT number(8) := 25800056;
    BILLLOANCLOSURE         CONSTANT number(8) := 25800057;
    BILLAMENDMENT           CONSTANT NUMBER(8) := 25800058;    
    BILLREVERSEDEAL         CONSTANT number(8) := 25800101;


--  Exports
    TRADERECEIVABLE         CONSTANT number(8) := 25900001;
    TRADECOLLECTION         CONSTANT number(8) := 25900002;
    TRADEPURCHASED          CONSTANT number(8) := 25900003;
    TRADEEFC                CONSTANT number(8) := 25900004;
    TRADEOVERDUE            CONSTANT number(8) := 25900005;
    TRADEBUYSPOT	          CONSTANT number(8) := 25900011;
    TRADEBUYFORWARD    	    CONSTANT number(8) := 25900012;

    COMMODITYHEDGEBUY       CONSTANT number(8) := 25900014;
    COMMODITYTRADEBUY       CONSTANT number(8) := 25900015;
    MONEYBORROWING          CONSTANT number(8) := 25900016;
    CFHEDGEBUY            CONSTANT number(8) := 25900018;
  --  CFTRADEBUY              CONSTANT number(8) := 25900019;

    COCALLHEDGEBUY          CONSTANT number(8) := 25900020;
    COPUTHEDGESALE          CONSTANT number(8) := 25900021;
    COPUTTRADESALE          CONSTANT number(8) := 25900022;
    COCALLTRADEBUY          CONSTANT number(8) := 25900023;



--  Imports
    TRADEPAYMENTS           CONSTANT number(8) := 25900053;
    TRADEIMPORTBILL         CONSTANT number(8) := 25900052;
    TRADESALESPOT	          CONSTANT number(8) := 25900061;
    TRADESALEFORWARD	      CONSTANT number(8) := 25900062;
    TRADEPCFC		            CONSTANT number(8) := 25900071;
    TRADEPSCFC              CONSTANT number(8) := 25900072;
    TRADEBUYERCREDIT	      CONSTANT number(8) := 25900073;
    TRADECONTRACT           CONSTANT number(8) := 25900086;
    TRADEPORDER             CONSTANT number(8) := 25900077;

    COMMODITYHEDGESALE      CONSTANT number(8) := 25900074;
    COMMODITYTRADESALE      CONSTANT number(8) := 25900075;
    MONEYDESPOSITS          CONSTANT number(8) := 25900076;


    CFHEDGESALE             CONSTANT number(8) := 25900078;
    CFTRADESALE             CONSTANT number(8) := 25900079;


    TRADETERMLOAN           CONSTANT number(8) := 25900081;

    ---OPTIONS
    COCALLHEDGESALE         CONSTANT number(8) := 25900082;
    COPUTHEDGEBUY           CONSTANT number(8) := 25900083;
    COCALLTRADESALE         CONSTANT number(8) := 25900084;
    COPUTTRADEBUY           CONSTANT number(8) := 25900085;

    --added by aakash 11-jun-13 01:51 pm
    FORWARDHEDGEBUY         CONSTANT number(8) := 25900011;
   -- FORWARDTRADEBUY   	    CONSTANT number(8) := 25900012;

    FORWARDHEDGESALE        CONSTANT number(8) := 25900061;
   -- FORWARDTRADESALE	      CONSTANT number(8) := 25900062;
    --end

-- Trade Category
    HEDGEDEAL               CONSTANT number(8) := 26000001;
    TRADEDEAL               CONSTANT number(8) := 26000002;
    FTDEAL                  CONSTANT number(8) := 26000003;

--  Risk Actions
    RISKACTSMS              CONSTANT number(8) := 26100001;
    RISKACTEMAIL            CONSTANT number(8) := 26100002;
    RISKACTBACKOFFICE       CONSTANT number(8) := 26100003;

    DAYTOOPEN               CONSTANT number(8) := 26400001;
    DAYOPEN                 CONSTANT number(8) := 26400002;
    DAYNOTOPENED            CONSTANT NUMBER(8) := 26400003;
    DAYCLOSEDCENTER         CONSTANT number(8) := 26400004;
    DAYCLOSED               CONSTANT number(8) := 26400005;
    DAYHOLIDAY              CONSTANT number(8) := 26400007;
    DAYWEEKLYOFF1           CONSTANT number(8) := 26400008;
    DAYWEEKLYOFF2           CONSTANT number(8) := 26400009;


    DAYOPENCHECK            CONSTANT number(8) := 26900001;
    CURRENCYCHECK           CONSTANT number(8) := 26900002;
    REMINDERCHECK           CONSTANT number(8) := 26900003;
    RATESCALC               CONSTANT number(8) := 26900004;
    DAYENDCHECK             CONSTANT number(8) := 26900021;
    PENDINGCONFORM          CONSTANT number(8) := 26900022;
    UPDATEPOSITION          CONSTANT number(8) := 26900023;
    MATUREDENTRY            CONSTANT number(8) := 26900024;

--  Deal Reversal
    DEALCANCEL              CONSTANT number(8) := 27000001;
    DEALDELIVERY            CONSTANT number(8) := 27000002;

    --  MM Transaction types
    MMBORROWING             CONSTANT NUMBER(8) := 27700001;
    MMINVESTMENT            CONSTANT NUMBER(8) := 27700002;

--  Currency Codes
    EUROCURRENCY            CONSTANT number(8) := 30400002;
    INDIANRUPEE             CONSTANT number(8) := 30400003;
    USDOLLAR                CONSTANT number(8) := 30400004;

    BUYER                   CONSTANT number(8) := 22000001;
    SUPPLER                 CONSTANT number(8) := 22000002;
    BOTHCUSTOMERS           CONSTANT number(8) := 22000003;

    --  Bank Record Type
    BANKCURRENT             CONSTANT number(8) := 25400001;
    BANKPRESHIMENT          CONSTANT number(8) := 25400002;
    BANKPOSTSHIPMENT        CONSTANT number(8) := 25400003;
    BANKNONFUNDBASE         CONSTANT number(8) := 25400004;

    --  Credit / Debit
    ENTRYCREDIT             CONSTANT number(8) := 14600001;
    ENTRYDEBIT              CONSTANT number(8) := 14600002;
    --Graphs

    GraphExchangeRate       Constant number(8) := 27200001;
    GraphHoldRate           Constant number(8) := 27200002;
    GraphDealRateBuy        Constant number(8) := 27200003;
    GraphDealRateSell       Constant number(8) := 27200004;
    GraphProfitLoss         constant number(8) := 27200005;
    GraphDealerWise         Constant number(8) := 27200006;
    GraphCurrWise           Constant number(8) := 27200007;
    GraphMonProfitLoss      Constant number(8) := 27200008;
    DealRateCancelRateBUY   Constant number(8) := 27200009;
    DealRateCancelRateSELL  Constant number(8) := 27200010;
    ExchRateComparision     Constant number(8) := 27200011;
    ExchangeRateBid         Constant number(8) := 27200012;
    ExchangeRateAsk         Constant number(8) := 27200013;


    --Reminder Code
    LOGINREMINDER           CONSTANT number(8) := 27600001;
    MAILREMINDER            CONSTANT number(8) := 27600002;

    --CA Voucher To Pass

    CAVOUCHERONVALUEDATE    CONSTANT number(8) := 29100001;
    CAVOUCHERONCANCELDATE   CONSTANT number(8) := 29100002;
    CAVOUCHERPROFITLOSS     CONSTANT number(8) := 29100003;

    --Broker Charges Type
    SingleLeg               CONSTANT number(8) := 29600001;
    BothLegs                CONSTANT number(8) := 29600002;

    OptionCall              CONSTANT number(8) := 32400001;
    OptionPut               CONSTANT number(8) := 32400002;

    Received                CONSTANT number(8) := 33200001;
    PremiumPaid             CONSTANT number(8) := 33200002;
    NoPremium               CONSTANT number(8) := 33200003;

--- Strage Types

    PlainVenela             Constant number(8) := 32300001;
    Stragles                CONSTANT number(8) := 32300011;
    Seagull                 Constant number(8) := 32300021;
    ExaticOptions           Constant number(8) := 32300051;
    Straddle                CONSTANT number(8) := 32300012;
--Exercise Type
    Exercise                Constant number(8) := 33000001;
    NoExercise              Constant number(8) := 33000002;
    CancelDeal              Constant number(8) := 33000003;

    MUTUALFUND_REDEPTION_FULL     CONSTANT Number(8)     := 43200001;
    MUTUALFUND_SWITCHIN_FULL      CONSTANT number(8)     := 43200002;
    MUTUALFUND_REDEPTION_PARTIAL  CONSTANT Number(8)     := 43200004;
    MUTUALFUND_SWITCHIN_PARTIAL   CONSTANT number(8)     := 43200005;

   MFFULLREDEMPTION        CONSTANT Number(8)     := 43200001;
    MFFULLSWITCHIN          CONSTANT number(8)     := 43200002;
    MFPARTIALREDEMPTION     CONSTANT Number(8)     := 43200004;
    MFPARTIALSWITCHIN       CONSTANT number(8)     := 43200005;

   -- MUTUALFUNDTRANREDEPTION    CONSTANT Number(8) := 43200001;
   -- MUTUALFUNDTRANSWITCHIN CONSTANT number(8)     := 43200002;
----  UOM Codes
--    UOMGRAMS                CONSTANT number(8) := 21800002;
--    UOMKILOS                CONSTANT number(8) := 21800004;
--
----  License Type
--    LICENSEIMPREST          CONSTANT number(8) := 22900001;
--    LICENSEEPCG             CONSTANT number(8) := 22900002;
--    LICENSEREP              CONSTANT number(8) := 22900003;
--    LICENSEBOND             CONSTANT number(8) := 22900004;
--    LICENSENONE             CONSTANT number(8) := 22900099;
--
----  Pack credit reasons
--    PCRFORIMPORTS           CONSTANT number(8) := 23500001;
--
----  Loan Types
--    LOANPCRUPEE             CONSTANT number(8) := 23600001;
--    LOANPCFC                CONSTANT number(8) := 23600002;
--    LOANPSLRF               CONSTANT number(8) := 23600003;
--    LOANPSLRR               CONSTANT number(8) := 23600004;
--    LOANPSCFC               CONSTANT number(8) := 23600005;
--
----  Interest Events
--    INTERESTADVANCE         CONSTANT number(8) := 23900001;
--    INTERESTPERIODIC        CONSTANT number(8) := 23900002;
--    INTERESTREVERSAL        CONSTANT number(8) := 23900003;
--    INTERESTUTILIZED        CONSTANT number(8) := 23900004;
--
----  Interest application types
--    APPLICATIONFINAL        CONSTANT number(8) := 24000001;
--    APPLICATIONPROVISIONAL  CONSTANT number(8) := 24000002;
--
----  Import Products
--    CUTNPOLISHEDDIAMOND     CONSTANT number(8) := 24200003;
--    PLAINGOLDBAR            CONSTANT number(8) := 24200012;
--  Day Statuses


--  DAYNPWD                 CONSTANT number(8) := 51800003;
--  DAYENDACTIVITY          CONSTANT number(8) := 51800006;
--  DAYSUSPENDED            CONSTANT number(8) := 51800009;
--  DAYBUNDH                CONSTANT number(8) := 51800010;
--   DAYUNSUSPEND            CONSTANT number(8) := 51800011;

--  Action Types
    ADDLOAD                 CONSTANT number(3) := 101;
    ADDSAVE                 CONSTANT number(3) := 102;
    EDITLOAD                CONSTANT number(3) := 103;
    EDITSAVE                CONSTANT number(3) := 104;
    VIEWLOAD                CONSTANT number(3) := 105;
    DELETELOAD              CONSTANT number(3) := 106;
    DELETESAVE              CONSTANT number(3) := 107;
    CONFIRMLOAD             CONSTANT number(3) := 108;
    CONFIRMSAVE             CONSTANT number(3) := 109;
    BROWSERLOAD             CONSTANT number(3) := 110;
    MENULOAD                CONSTANT number(3) := 111;
    USERVALIDATE            CONSTANT number(3) := 112;
    INVOICELOAD             CONSTANT number(3) := 121;
    PICKUPLOAD              CONSTANT number(3) := 122;
    INVOICELOTVIEW          CONSTANT number(3) := 123;
    INVOICECONSIGNEEINFO    CONSTANT number(3) := 124;
    INVOICECUSTOMRATE       CONSTANT number(3) := 125;
    ACTIONDATA              CONSTANT number(3) := 131;


    REPORTMENULOAD          CONSTANT number(3) := 151;
    REPORTDATASET           CONSTANT number(3) := 152;

--  NodeChangeDirection
     XmlField               constant number(1) := 0;
     FieldToXML             Constant number(1) := 1;
     XMLToField             Constant number(1) := 2;

--  Ref Cursor Types returned
    REFPICKUPLIST           CONSTANT number(4) := 1001;
    REFPICKUPENTITY         CONSTANT number(4) := 1002;
    REFPICKUPCOMBO          CONSTANT number(4) := 1003;
    REFPICKUPFORM           CONSTANT number(4) := 1004;
    REFXMLFIELDS            CONSTANT number(4) := 1005;
    REFMENUITEMS            CONSTANT number(4) := 1006;
    REFDICTIONARY           CONSTANT number(4) := 1007;
    REFXMLLOTDETAIL         CONSTANT number(4) := 1008;
    REFRELATION             CONSTANT number(4) := 1009;
    REFINVOICEPICK          CONSTANT number(4) := 1010;
    REFCONSIGNEE            CONSTANT number(4) := 1011;
    REFCUSTOMRATE           CONSTANT number(4) := 1012;
    REFUSERINFO             CONSTANT number(4) := 1013;
    REFACCESSCONTROL        CONSTANT number(4) := 1014;
    REFACCESSGROUP          CONSTANT number(4) := 1015;
    REFLOGININFO            CONSTANT number(4) := 1016;
    REFLCDETAILS            CONSTANT number(4) := 1017;
    REFGLDETAILS            CONSTANT number(4) := 1018;
    REFGLINFORMATION        CONSTANT number(4) := 1019;
    REFINVOICELOAN          CONSTANT number(4) := 1020;
    REFINVOICEINFO          CONSTANT number(4) := 1021;
    REFINVOICEPSL           CONSTANT number(4) := 1022;
    REFPSLINTEREST          CONSTANT number(4) := 1023;
    REFPACKINGCREDIT        CONSTANT number(4) := 1024;
    REFPCINTEREST           CONSTANT number(4) := 1025;
    REFINVOICEPSCFC         CONSTANT number(4) := 1026;
    REFPSCFCINTEREST        CONSTANT number(4) := 1027;
    REFSHIPMENTINFO         CONSTANT number(4) := 1028;
    REFSHIPMENTPICK         CONSTANT number(4) := 1029;
    REFLICENSEIMPREST       CONSTANT number(4) := 1030;
    REFLICENSEEPCG          CONSTANT number(4) := 1031;
    REFLICENSEREP           CONSTANT number(4) := 1032;
    REFLICENSEBOND          CONSTANT number(4) := 1033;
    REFLICENSEGOLD          CONSTANT number(4) := 1034;
    REFIMPORTADVANCE        CONSTANT number(4) := 1035;
    REFIMPORTRATES          CONSTANT number(4) := 1036;
    REFLOANLIMITS           CONSTANT number(4) := 1037;
    REFPCFCIMPORT           CONSTANT number(4) := 1038;
    REFBRCIMPORT            CONSTANT number(4) := 1039;
    REFEXPORTRATES          CONSTANT number(4) := 1040;
    REFLOANDETAILS          CONSTANT number(4) := 1041;
    REFBOEBOND              CONSTANT number(4) := 1042;
    REFBOEGOLD              CONSTANT number(4) := 1043;
    REFIMPORTLC             CONSTANT number(4) := 1044;
    REFSUPPLIERINFO         CONSTANT number(4) := 1045;
    REFGOLDREQUEST          CONSTANT number(4) := 1046;
    REFGOLDRECEIPT          CONSTANT number(4) := 1047;
    REFRECEIPTSPECIFIC      CONSTANT number(4) := 1048;
    REFLOANGOLD             CONSTANT number(4) := 1049;
    REFALLUSERS             CONSTANT number(4) := 1050;
    REFSECURITYPOLICY       CONSTANT number(4) := 1051;
    REFMAXMENUID            CONSTANT number(4) := 1052;
    REFTRNUSERDETAILS       CONSTANT number(4) := 1053;
    REFTRNALLUSERDETAILS    CONSTANT number(4) := 1054;
    REFRISKDETAILS          Constant number(4) := 1055;
    REFREPORTMENU           constant number(4) := 1056;
     -- Modified by by Manjunath Reddy on 05/03/2008 For Geting Risk Params
    REFRISKPARAM            Constant number(4) := 1057;
    REFTRADEREGISTER        constant number(4) := 1058;
    REFTRADESPECIFIC        CONSTANT number(4) := 1059;
    REFTRADEDEALS           CONSTANT number(4) := 1060;
    REFPOSITIONSHEET        CONSTANT number(4) := 1061;
    REFPOSITIONGROUP        CONSTANT number(4) := 1062;
    REFRISKPOSITION         CONSTANT number(4) := 1063;
    REFRISKPOSITION1        CONSTANT number(4) := 1064;
    REFDEALCURRENCYRATE     CONSTANT number(4) := 1065;
    REFHOLIDAYFILE          CONSTANT number(4) := 1066;
    REFREPORTGROUPS         CONSTANT number(4) := 1067;
    REFREPORTCODES          CONSTANT number(4) := 1068;
    REFREPORTBROWSER        CONSTANT number(4) := 1069;
    REFCHILDREPORT          CONSTANT number(4) := 1070;
    REFREPORTPARAM          CONSTANT number(4) := 1071;
    REFTABLENAMES           CONSTANT number(4) := 1072;
    REFFIELDNAMES           CONSTANT number(4) := 1073;
    REFDAYDETAILS           constant number(4) := 1074;
    REFDAYTOOPEN            constant number(4) := 1075;
    REFDAYOPENCALC          CONSTANT number(4) := 1076;
    REFDAYCLOSECALC         CONSTANT number(4) := 1077;
    REFDAYOPENED            CONSTANT number(4) := 1078;
    REFREMINDER             CONSTANT number(4) := 1079;
    REFDEALS                CONSTANT number(4) := 1080;
    REFHOLDINGRATE          CONSTANT number(4) := 1081;
    REFPARTICULARDEAL       CONSTANT number(4) := 1082;
    REFLOANREPAYMENT        CONSTANT number(4) := 1083;
    REFHOLDINGRATEUSER      CONSTANT number(4) := 1084;
    REFTRADELOANS           CONSTANT number(4) := 1085;
    REFRISKUSER             CONSTANT number(4) := 1086;
    REFLOANSPECIFIC         CONSTANT number(4) := 1087;
    REFMATURITYDATECALC     CONSTANT number(4) := 1088;
    REFDEALRISKCALC         CONSTANT number(4) := 1089;
    REFBANKACCOUNT          CONSTANT number(4) := 1090;
    REFREVERSEDEAL          CONSTANT number(4) := 1091;
    REFREVERSELOAN          CONSTANT number(4) := 1092;
    REFGRAPHS               CONSTANT number(4) := 1093;
    REFHEDGEAMOUNT          CONSTANT number(4) := 1094;
    REFTRANEXCESS           CONSTANT number(4) := 1095;
    REFCURRENCYRATES        CONSTANT number(4) := 1096;
    REFAPPLYRATES           CONSTANT number(4) := 1097;
    REFSMSMAIL              CONSTANT number(4) := 1098;
    REFRATES                CONSTANT number(4) := 1099;
    REFBASECURRENCY         CONSTANT number(4) := 1100;
    REFCOMPANYDETAILS       CONSTANt number(4) := 1101;
    REFHEDGERISK            CONSTANT number(4) := 1102;
    REFHEDGERISK1           CONSTANT number(4) := 1103;
    REFKEYGROUP             CONSTANT number(4) := 1104;
    REFQUERY                CONSTANT number(4) := 1105;
    REFCUSTOMERDETAILS      CONSTANT number(4) := 1106;
    REFCURRENTSTATEMENT     CONSTANT number(4) := 1107;
    REFREPORTIDS            CONSTANT number(4) := 1108;
    REFPERIODICREPORT       CONSTANT number(4) := 1109;
    REFDYNAMICFUNCTIONS     CONSTANT number(4) := 1110;
    REFDYNAMICQUERY         CONSTANT number(4) := 1111;
    REFARGUMENTS            CONSTANT number(4) := 1112;
    REFBIDASKRATES          CONSTANT number(4) := 1113;
    REFVOUCHERREFERENCE     CONSTANT number(4) := 1114;
    REFVOUCHERDETAIL        CONSTANT number(4) := 1115;
    REFUSERTERMINAL         CONSTANT number(4) := 1116;
    REFEXCHANGERATE         CONSTANT number(4) := 1117;
    REFENTITY               CONSTANT number(4) := 1118;
    REFFIELDS               CONSTANT number(4) := 1119;
    REFMARKETDEALS          CONSTANT number(4) := 1121;
    REFBASERATE             CONSTANT number(4) := 1122;
    REFDUEDATE              CONSTANT number(4) := 1123;
    REFCROSSDEALDETAILS     CONSTANT number(4) := 1124;
    REFWORKINGDAYS          CONSTANT number(4) := 1125;
    REFALLDEALS             CONSTANT number(4) := 1126;
    REFDEALPROFILE          CONSTANT number(4) := 1127;
    REFSAVEREPORTS          CONSTANT number(4) := 1128;
    REFDETAILASSLIAB        CONSTANT number(4) := 1129;
    REFGROUPASSLIAB         CONSTANT number(4) := 1130;
    REFCURRENTACCOUNT       CONSTANT number(4) := 1131;
    REFFIXEDDEPOSIT         CONSTANT number(4) := 1132;
    REFBCRFIXEDDEPOSIT      CONSTANT number(4) := 1133;
    REFPURCHASEORDER        CONSTANT number(4) := 1134;
    REFHEDGEDEALS           CONSTANT number(4) := 1135;
    REFHEDGESPECIFIC        CONSTANT number(4) := 1136;
    REFPICKENTITY           CONSTANT number(4) := 1137;
    REFPICKRELATION         CONSTANT number(4) := 1138;
    REFVEDIOHELP            CONSTANT number(4) := 1139;
    REFSHORTCUTLIST         CONSTANT number(4) := 1140;
    REFPRODUCTDOC           CONSTANT number(4) := 1141;
    REFSHORTUSER            CONSTANT number(4) := 1142;
    REFBUYERSLOAN           CONSTANT number(4) := 1143;
    REFBUYERSLOANSPECIFIC   CONSTANT number(4) := 1144;
    REFDEALLINKING          CONSTANT number(4) := 1145;
    REFORDERLINKING          CONSTANT number(4) := 3043;
    REFVARANALYSIS          CONSTANT number(4) := 1146;
    REFRISKACTION           CONSTANT number(4) := 1147;
    REFTRADELINKING         CONSTANT number(4) := 1148;
--    REFALLDEALS             CONSTANT number(4) := 1149;
    REFHEDGEDEALLINKING     constant number(4) := 1150;
    REFLINKBATCHNO          CONSTANT number(4) := 1151;
    REFORDINVLINKING        CONSTANT number(4) := 1152;
    REFORDINVLINKINGRS1     CONSTANT number(4) := 1153;
    REFORDINVLINKINGRS2     CONSTANT number(4) := 1154;
    REFCUSTOMRATEIMP        CONSTANT NUMBER(4) := 1155; -- added by ishwarachandra
    REFFIXEDDEPOSITCLOSURE  CONSTANT NUMBER(4) := 1156;  --added by Gouri for fixed deposit Closure

    REFTRADEDEALUSERWISE    constant number(4) := 1157;
    REFTRADEDEALCURRENCYWISE constant number(4) :=1158;
    REFPOSITIONGAPVIEW      CONSTANT number(4) := 1160;
    REFPOSITIONGAPVIEWGRID  CONSTANT NUMBER(4)  :=1161;
    REFSUBREPORTLIST        CONSTANT number(4) := 1162;
    REFCONTRACTDETAILS      CONSTANT number(4) := 1163;
    REFBCINTEREST           CONSTANT number(4) := 1164;--added by manjunath sir 05052014
    REFVENDORCUSTOMER       CONSTANT number(4) := 1165;--added by manjunath sir 12052014
    REFREMITTANCEREFERENCE  CONSTANT number(4) := 1166;--added by manjunath sir 12052014
    



    REFACCOUNTNUMBER        CONSTANT number(4) := 1167;
    REFBANKWITHCURRENTACC   CONSTANT number(4) := 1168;
    REFREVERSEDTLS          CONSTANT number(4) := 1169;  ---in TOI source it was 1168
    
    REFCURRENCYLABEL        CONSTANT number(4) := 1170;


    REFBANKWITHCURACANDNBFC  CONSTANT number(4) := 1171;
    REFPORTFOLIO            CONSTANT number(4) := 1172;
    REFFDADVICELTR          CONSTANT number(4) := 1173;  
    REFACCOUNTMAPPINGDEATILS CONSTANT number(4) := 1174;  
    REFDEBTDETAIL            CONSTANT number(4) := 1175; 
    REFBONDSCHEMEDETAIL      CONSTANT number(4) := 1176;
    REFBONDPURCHASEDETAIL    CONSTANT number(4) := 1177; 
    REFBONDINTERESTCHARGE    CONSTANT number(4) := 1178; 
    REFPERIODDETAILS         CONSTANT number(4) := 1179;  
    REFYTM                   CONSTANT number(4) := 1180;
    REFBONDINTDETAILS        CONSTANT NUMBER(4) := 1181;
    Refbondscheme            Constant Number(4) := 1182;
    
   
    refScrennameedit         CONSTANT number(4) := 1366;
    refPeriodTypeFetch       CONSTANT number(4) := 1367;
    Refchargetypeedit        Constant Number(4) := 1368;
    Refbankchargelinkentity   Constant Number(4) := 1369;
    Refbankchargelinkref        Constant Number(4) := 1371;
    REFBANKCHARGEMASTERGRID  CONSTANT number(4) := 1258;  
---- Commodities Module ----------------------------------------------------------
    REFMATURITYDATE         CONSTANT number(4) := 1201;
    REFGETCOMMODITYPARAM    CONSTANT number(4) := 1202;
    REFPRODUCTDETAILS       CONSTANT number(4) := 1203;
    REFREVERSALDEAL         CONSTANT number(4) := 1204;
    REFCOMMODITYVALUE       CONSTANT number(4) := 1205;
    REFBROKERS              CONSTANT number(4) := 1206;
    REFPRODUCTS             CONSTANT number(4) := 1207;
    REFCOMMMTMRATE          CONSTANT number(4) := 1208;
    REFPRODUCTLIST          CONSTANT number(4) := 1209;
    REFCOMMRISKPARAM        CONSTANT number(4) := 1210;
    REFCOMMRISKDETAILS      CONSTANT number(4) := 1211;
    REFCOMMOUTSTANDINGDEAL  CONSTANT number(4) := 1212;
    REFTFDATAUPDATES        CONSTANT number(4) := 1213;
    REFPHYSICALTRADES       CONSTANT number(4) := 1214;        

    REFMISCURSOR31           CONSTANT NUMBER(4) := 1309;
    REFMISCURSOR32           CONSTANT number(4) := 1310;
    REFMISCURSOR33           CONSTANT number(4) := 1311;

-----Currency Futures-------------------------------------------------------------
    REFFUTUREREVERSALDEAL   CONSTANT number(4) := 1401;
    REFFUTUREOUTSTANDING    CONSTANT number(4) := 1402;
    REFFUTUREVALUE          CONSTANT number(4) := 1403;
    REFCURRENCYFUTURERATES  CONSTANT number(4) := 1404;
    REFVIEWDEALSMATURITYDATE CONSTANT number(4):= 1405;
    REFPARTICULARFUTUREDEAL CONSTANT number(4) := 1406;--aakash-14-mar-13
    
----- Derivatives Module----------------------------------------------------------
    REFOPTIONTRADES         CONSTANT number(4) := 1501;
    REFREFRATES             CONSTANT number(4) := 1502;
    REFOPTIONLEGS           CONSTANT number(4) := 1503;
    REFOPTIONSPL            CONSTANT number(4) := 1504;
    REFSPECIFICTRADE        CONSTANT number(4) := 1505;
    REFLINKEDDEALS          CONSTANT number(4) := 1506;
    
    REFEXCELREPORTSET       CONSTANT NUMBER(4) := 1508;   -- Added by Sivadas on 22 Sep 2011 for excel report
    REFEXCELREPORTDATA      CONSTANT number(4) := 1509;   -- Added by Sivadas on 22 Sep 2011 for excel report
    REFEXCELREPORTDETAIL    CONSTANT number(4) := 1510;   -- Added by Sivadas on 27 Sep 2011 for excel report

    REFBANKSTAT             CONSTANT number(4) := 1511;   -- for MTM Stmt upload
    REFBANKSTATDETAIL       CONSTANT number(4) := 1512;   -- for MTM Stmt upload
    REFUSERREFUPDATE        CONSTANT number(4) := 1513;   -- Added on 21 Dec 2011 to get user reference no. data
    REFUSERREFUPDATEREC     CONSTANT number(4) := 1514;   -- Added on 21 Dec 2011 for MTM Stmt upload
    REFGETUPLOADEDDATA      CONSTANT number(4) := 1515;   -- Added on 21 Dec 2011 for MTM Stmt upload
    REFGETRBISPOTRATE       CONSTANT number(4) := 1516;   -- Added on 29 Dec 2011 for MTM Stmt upload (get deal rbi usd rate)
    REFGAPVIEWSUMMARY       CONSTANT number(4) := 1517;   -- added on 24 Apr 2012 for Cash flow statement
    REFGAPVIEWDETAILS       CONSTANT number(4) := 1518;   -- added on 24 Apr 2012 for Cash flow statement
    REFNSESTAT              CONSTANT number(4) := 1519;   -- added on 03 Aug 2012 for NSE Upload
    REFOPTIONSMTM           CONSTANT number(4) := 1521;   -- Added on 29/06/13 for Options' MTM entry
    REFOPTIONSMTM1          CONSTANT number(4) := 1522;   -- Added on 01/07/13 for Options' MTM entry
    REFCUSTOMERDETAIL       CONSTANT number(4) := 1523;
    REFGOLDPARAMETER        CONSTANT number(4) := 1524;    
    REFGOLDOPTION           CONSTANT number(4) := 1525;    
    refgetbudgetrate                constant number(4):= 1526;
    refloadbudgetdata               constant number(4):= 1527;
    REFFAIRVALUATION                CONSTANT number(4) := 1528;
    REFBANKCHARGEABLES      CONSTANT number(8) := 1529;    
  
    Refinflowoutflowdetails Constant Number(4) := 1530;
    Refretreivedeals        Constant Number(4) := 1531;
    refedcchargeDeals       CONSTANT number(4) := 1532;
    refmisplaceholder       CONSTANT number(4) := 1533;
    REFBANKACCOUNTNUMBER     CONSTANT NUMBER(4) :=1537;
    REFGetCurrentAccountNumber CONSTANT NUMBER(4):=1538;    
    refGetMTMData           CONSTANT NUMBER(4) := 1542;   
    REFGETDIRECTINDIRECT    CONSTANT NUMBER(4) := 1545;
    REFDEALSVIEW            CONSTANT NUMBER(4) := 1601;
    REFBLOOMBERG            CONSTANT number(4) := 1602;
    REFBLOOMBERG1           CONSTANT number(4) := 1603;
    REFMARGINSUMMARY        CONSTANT number(4) := 1604;
    REFMARGINDEALS          CONSTANT number(4) := 1605;
    REFBANKCOLLATERAL       CONSTANT number(4) := 1606;
    REFONANDOFFSHORE        CONSTANT number(4) := 1607;
    REFAANDLPOSITION        CONSTANT number(4) := 1608;
    REFAANDLTRANS           CONSTANT number(4) := 1609;
    REFAANDLTRADE           CONSTANT number(4) := 1610;
    REFAANDLDEAL            CONSTANT number(4) := 1611;
    CONTRACTBUCKETTING      CONSTANT number(8) := 1612;
    REFEXISTINGCONTRACT     CONSTANT number(8) := 1613;
    REFSUBREPORT            CONSTANT number(8) := 1614;
    REFSTRESSDETAIL         CONSTANT NUMBER(8) := 1615;
    Refstresspnlcurrency    Constant Number(8) := 1616;
    REFSTRESSPNLCOMPANY     CONSTANT NUMBER(8) := 1617;
    Refstresspnlrate        Constant Number(8) := 1618;
    Refstresspnledit        Constant Number(8) := 1619;
    REFSTRESSPNLCURRENCYDETAILED Constant Number(8) := 1620;
    REFVARIATIONMTM         CONSTANT number(8) := 1621;
    REFREMAINDERLIST        CONSTANT number(8) := 1622;
    REFFDSCHEM              CONSTANT number(8) := 1623;
    REFMUTUALFUNDSCHEME     CONSTANT number(4) := 1624;
    REFMUTUALFUNDDETAILS    CONSTANT number(4) := 1625;
    REFDEPOSITDATA          CONSTANT number(4) := 1626;
    REFDEPOSITCLOSURE       CONSTANT number(4) := 1627;
    REFINTPLAN              CONSTANT number(4) := 1628;
    REFFDCALCULATOR         CONSTANT number(4) := 1629;
    REFTDSPLAN              CONSTANT number(4) := 1630;
    REFTDSRATEEDIT          CONSTANT number(4) := 1631;
    REFTLDETAILS            CONSTANT number(4) := 1632;
    REFTLREPAY              CONSTANT number(4) := 1633;
    REFTERMLOAN             CONSTANT number(4) := 1634;
    REFTLSINGLE             CONSTANT number(4) := 1635;
    REFINTDETAILS           CONSTANT NUMBER(4) := 1636;
    REFFDINTRATES           CONSTANT number(4) := 1637;
    REFAUTORENEWAL          CONSTANT number(4) := 1639;
    REFAUTORNWLDISP         CONSTANT number(4) := 1640;
    REFFDINTERESTCHARGE     CONSTANT number(4) := 1641;
    REFFDDTLS               CONSTANT number(4) := 1642;
    REFFDPRECLOSEDTLS       CONSTANT number(4) := 1643;

    REFMFAMCCODE            CONSTANT number(4) := 1645;
    REFFDDETAILREPORT       CONSTANT number(4) := 1646;
    REFNAVCODE              Constant number(4) := 1647;
    REFTRANSACTIONSLIP      constant number(4) := 1648;
    REFFUNDTRANSFER         constant number(4) := 1649;

    REFTRANSACTIONINFO      CONSTANT number(4) := 1650;
    REFCORPUSUPDATE         CONSTANT number(4) := 1652;
    REFINSERTDATA           CONSTANT number(4) := 1653;

    REFAUDITTRAIL           CONSTANT number(4) := 1654;
    REFAUDITTRAILTYPE       CONSTANT number(4) := 1655;
    REFAUDITTRAILDETAIL     CONSTANT number(4) := 1656;
    REFFIFOBALANCE          CONSTANT number(4) := 1657;
    REFCPCDDETAILS          CONSTANT number(4) := 1658;
    REFRECEIPTNOFILL        CONSTANT number(4) := 1659;
    REFMULTIPLERECEIPTNO    CONSTANT number(4) := 1660;
    REFINTERFACEEDIT        CONSTANT number(4) := 1661;
    REFINTEFACEUPDATE       CONSTANT number(4) := 1662;
    REFBANKLIST             CONSTANT number(4) := 1663;
    REFUSERUPDATE           CONSTANT NUMBER(4) := 1665;
    REFBACKENDUPDATES             CONSTANT number(4) := 1666;
    REFREFERENCENOSELECTION         CONSTANT number(4) := 1667;
    REFSCHEMESELECTION             CONSTANT number(4) := 1668;
    REFSCHEMECODESELECTION         CONSTANT number(4) := 1669;
    REFMFBACKENDUPDATE             CONSTANT number(4) := 1670;
    REFNAVSELECTION                 CONSTANT NUMBER(4) := 1671;
    REFSCHEMESELECTIONFD           CONSTANT number(4) := 1672;    
    RefExposureUploadDetails       CONSTANT number(4) := 1673;
    RefContractExposureDetails      CONSTANT number(4) := 1674;
    RefContractExposureSummary      CONSTANT number(4) := 1675;
    RefContractExposureDetails_app  Constant number(4) := 1676;
    refPreviousUploaddates          Constant number(4) := 1677;
    REFEXPDETAILS                   CONSTANT number(4) := 1678;
    RefVarCovarPositionPopulate     Constant number(4) := 1680;
    RefVarCovarResults              Constant number(4) := 1681;
    RefVarCovarResults1             Constant number(4) := 1682;
    RefVarCovarHedgeRatio           Constant number(4) := 1683;
    
    refFRADetails                   CONSTANT number(4) := 1700;    
    refIFRDetails                   CONSTANT number(4) := 1701; 
    refIRSLinkDetails               CONSTANT number(4) := 1702; 
    REFVARCURSOR1                   CONSTANT number(4) := 1703;
    REFREPAYMENTSCHEDULE            CONSTANT number(4) := 1704;  
    REFREPAYMENTSCHEDULEEDIT        CONSTANT number(4) := 1705; 
    REFLOANSCHEME                   CONSTANT number(4) := 1706; 
    refAlmView                      CONSTANT number(4) := 1707; 
    refAlmViewDetail                CONSTANT number(4) := 1708; 
    refIRSSettlement                CONSTANT NUMBER(4) := 1709;		

    REFGETIMAGES             CONSTANT NUMBER(4) :=1186;
    REFSCANNEDIMAGESACL      CONSTANT NUMBER(4) := 1362;
    Refdocumentstorage       Constant Number(4) := 1363;
    REFDocumentStorageCOLS   CONSTANT number(4) := 1364;

    -- Forward Rollover
    REFROLLOVERDELETE               CONSTANT NUMBER(4):=1535;
    REFROLLOVERFORWARD              CONSTANT NUMBER(4):=1536;
    -- Forward Rollover
    refLoanDetailsForLink     CONSTANT number(4) :=1711;  --       
    refIRSInterestSellDetails CONSTANT number(4) :=1712;  --   
    refIRSInterestBuyDetails  CONSTANT number(4) :=1713;  --   
    refIRSRollerCosterDetails CONSTANT number(4) :=1714;  -- 
    
    REFIRSHOLIDAYVALIDATION         CONSTANT number(4) := 1715;
    REFIRSUNDERLYING                CONSTANT number(4) := 1716;
    REFIRSUNDERLYINGDETAILS         CONSTANT number(4) := 1717;
    refIrsDetails                   CONSTANT NUMBER(4) := 1718;
    refCCIRSSettlement              CONSTANT NUMBER(4) := 1719;
    refCCIrsDetails                 CONSTANT NUMBER(4) := 1720;
    refIrsPaymentCalendar           CONSTANT NUMBER(4) := 1721;
    refIrsFixingCalendar            CONSTANT NUMBER(4) := 1722;
    refIRSInterestCalculation       CONSTANT NUMBER(4) := 1723;
    refIRSHolidayList               CONSTANT NUMBER(4) := 1724;
    refTradedtls                    CONSTANT NUMBER(4) := 1725;
    refMaturityPopulate             CONSTANT NUMBER(4) := 1764;    
    refCBFCFORMAT                   CONSTANT NUMBER(4) := 1762;
    REFWORDREPORTLIST               CONSTANT NUMBER(4) := 1727;
    REFGETMUTUALFUNDNORMSDATA       CONSTANT NUMBER(4) := 1742;
    refCBCANCELLATION               CONSTANT NUMBER(4) := 1763;
    refdealername                   CONSTANT NUMBER(4) := 1765;  
    refProdMaturityPopulate         CONSTANT NUMBER(4) := 1766; 
    refcheckMatDate                 CONSTANT NUMBER(4):=  1767;
    refExposureEdit                 CONSTANT NUMBER(4):=  1768;
    refGetExposure                  CONSTANT NUMBER(4):=  1769;
    refGetForward                   CONSTANT NUMBER(4):=  1770;
    refFrowardBatchno               CONSTANT NUMBER(4):=  1771;
    refExposureLinkDelete           CONSTANT NUMBER(4):=  1772;
    Refdeallinkdelete               Constant Number(4):=  1773;
    --------data uplaod---------
     REFGETSYNONYMNAME              Constant Number(4):= 1774;
     REFGETXMLFIELD                  Constant Number(4):= 1775;
     refbulkuploaddata               Constant Number(4):= 1776;
     refgetmasterlist                Constant Number(4):= 1777;
     refgetmasterdata                Constant Number(4):= 1778;     
     refclearstagingtabledata        Constant Number(4):= 1779;
     refValidatestagingtabledata     Constant Number(4):= 1780;    
     refgetmasterdataCloud           Constant Number(4):= 1750; 
     refgetxmlfieldcloud             CONSTANT NUMBER(4):= 1751;
     refgetfileuploaddetailscloud             CONSTANT NUMBER(4):= 1752;
     refgetfiledetailscloud             CONSTANT NUMBER(4):= 1753;
      refgetsynonymdetailscloud            Constant Number(4):= 1754;
     Refgetmasterdata1               Constant Number(4):= 1781;
     refValidatestagingtabledata1    Constant Number(4):= 1782;
     Refgetshortdescription          Constant Number(4):= 1783;
     Refgetfxalldata                 Constant Number(4):= 1784;
     Refloadfxalldata                Constant Number(4):= 1786;
     Refgetfuturesdata               Constant Number(4):= 1785;
     REFLOADFUTURESDATA              CONSTANT NUMBER(4):= 1787;
      Refloadnewdeals                Constant Number(4):= 1788;
     REFLOADFUTUREDEALS             CONSTANT NUMBER(4):= 1789;
     refloadfutureoutdeals          CONSTANT NUMBER(4):= 1790;
     REFGETEXISTFUTUREDATA           CONSTANT NUMBER(4):= 1791;
    --refCBFCFORMAT                   CONSTANT NUMBER(4) := 1762;
     refloadcanceldeals              CONSTANT NUMBER(4):= 1792;
     REFEXPOUTDETAILS                CONSTANT NUMBER(4):= 1793;
     
     reffwdoutdeals                  constant number(4):= 1794;
     reffwdcanceldeals               constant number(4):= 1795;
     reffutureoutdeals               constant number(4):= 1796;
     reffuturecanceldeals            constant number(4):= 1797;
     refoptoutdeals                  constant number(4):= 1798;
     refoptcanceldeals               constant number(4):= 1799;
     REFPERIODICREPORTMAIL           constant number(4):= 1800;
     refGetForwardCross              constant number(4):= 1801;
     refDealLinkDeletecross          constant number(4):= 1802;
     refGetForwarddetails            constant number(4):= 1803;
     refRBIrate                      constant number(4):= 1804; 
     
    refDashboardPosition    constant number(4) :=3003;
    refDashboardPosition_detail    constant number(4) :=3004;
    refDealsMonitoring      constant number(4) :=3005;
    REFPOSITIONGAPVIEWNEW      CONSTANT number(4) := 3001;
    REFPOSITIONGAPVIEWGRIDNEW  CONSTANT NUMBER(4)  :=3002;
    RefNOPDashBoard         CONSTANT NUMBER(4)  :=3006;
    REFIMAGESCANNING       CONSTANT NUMBER(4)  :=3010;
    REFIMAGEGRIDDATA       CONSTANT NUMBER(4)  :=3011; 
    REFHEDGESTATUS          CONSTANT NUMBER(4)  :=3012;
    REFFXSETTLEMENT         CONSTANT NUMBER(4)  :=3013;
    refGENPICKUP            CONSTANT NUMBER(4)  :=3000;
    REFHEDGESTATUSDRILL     CONSTANT NUMBER(4)  :=3014;
    REFHEDGESTATUSDRILLSUB   CONSTANT NUMBER(4)  :=3015;

    
    REFLIMITDASHBOARD        CONSTANT NUMBER(4)  :=3016;
    REFLIMITDRILL            CONSTANT NUMBER(4)  :=3017;
    REFBANWISELIMIT          CONSTANT NUMBER(4)  :=3018;
    
    REFSTOPLOSS               CONSTANT NUMBER(4)  :=3019;
    RefNOPDashBoard_Details   CONSTANT NUMBER(4)  :=3020;
    REFGRIDSCHEMA             CONSTANT number(4):=3021;
    refDashboardBudget        CONSTANT number(4):=3022;
    refDashboardPortfolio     CONSTANT number(4):=3023;
    refDashboardDealer        CONSTANT number(4):=3024;
    --refDashboardCurrency      CONSTANT number(4):=3025;
    refRiskMonitoring          constant number(4) :=3025;
    refRiskMonitoring_detail   constant number(4) := 3026;
    refUserDataFormat          CONSTANT number(4):=3035;
    refEntityTABList           Constant number(4):=3028;
            -- added by manjunath reddy on 02/04/2019 to take care other than add data 
    REFGETLOADDATA         Constant number(4) :=3027;
    REFPROGRAMUNITVALIDATION   CONSTANT NUMBER(4):= 3029;
    REFFXSUMMARYLOCWISE     CONSTANT number(4):= 3031;
    REFFXSUMMARYFWDOPT        CONSTANT number(4):= 3032;
    REFUSERALERTS             CONSTANT NUMBER(4):= 3034;
    CURSORGRIDTEST            CONSTANT NUMBER(4)  := 3038;
    REFMONTHLYSETTLEMENT      CONSTANT NUMBER(4)  := 3040;
    REFFXSETTLEMENTNEW        CONSTANT NUMBER(4)  := 3041;
    REFUSERALERTS_Details     CONSTANT NUMBER(4)  := 3042;
    refDeliveryBatchNo        CONSTANT NUMBER(4)  := 3044;
    RefGetSynonymsList           CONSTANT NUMBER(4)  := 3045;
    RefGetSynonymScreenData      CONSTANT NUMBER(4)  := 3046;
    REFDMSSYNONYMS            CONSTANT NUMBER(4) := 3047;
      REFDMSDETAILS            CONSTANT NUMBER(4) := 3048;
    REFRATESTICKER                  constant number(4) := 4001;   
    
    
    -- Entity Types
    AGENTMASTER		          constant number(4) := 2001;
    BASISMASTER 	          constant number(4) := 2002;
    BUYERBANKMASTER 	      constant number(4) := 2003;
    BUYERMASTER 	          constant number(4) := 2004;
    COMPANYMASTER 	        constant number(4) := 2005;
    COUNTRYMASTER 	        constant number(4) := 2006;
    CURRENCYMASTER 	        constant number(4) := 2007;
    CUSTOMHOUSEMASTER 	    constant number(4) := 2008;
    GOODSCLASSMASTER 	      constant number(4) := 2009;
    MANUFACTUREHOUSEMASTER  constant number(4) := 2010;
    RAWMATERIALMASTER 	    constant number(4) := 2011;
    SHIPMENTMODEMASTER 	    constant number(4) := 2012;
    SHIPPINGAGENTMASTER     constant number(4) := 2013;
    SUPPLIERBANKMASTER 	    constant number(4) := 2014;
    SUPPLIERMASTER 	        constant number(4) := 2015;
    PRODUCTMASTER 	        constant number(4) := 2016;
    USERMASTER 		          constant number(4) := 2017;
    POLICYFILE 		          constant number(4) := 2018;
    PICKUPMASTER 	          constant number(4) := 2019;
    HOLIDAYMASTER           CONSTANT number(4) := 2020;
    MENUMASTER              CONSTANT number(4) := 2021;



-- Commodity Date Type
    NextWorkingDate         Constant number(1) :=1;
    SpotDate                Constant number(1) :=2;
    ForwardMonths           Constant number(1) :=3;
--  CommodityProfitType
    MTMPANDL                constant number(1):=  1;
    TOTALPANDL              constant number(1):=  2;

-- Commdeal Amount
    DealAmount              Constant number(1) :=1;
    MTMRate                 Constant number(1) :=2;

-- Comm Margin amount
    TodayMargin             Constant number(1) :=1;
    YesterdayMargin         Constant number(1) :=2;

--  Extract Parameters from XML Document
    PARAMSTRING             CONSTANT number(1) := 1;
    PARAMNUMBER             CONSTANT number(1) := 2;
    PARAMDATE               CONSTANT number(1) := 3;
    PARAMXMLTYPE            CONSTANT number(1) := 4;

--  Input Parameter type for the above
    TYPENODENAME            CONSTANT number(1) := 1;
    TYPENODEPATH            CONSTANT number(1) := 2;

--  For Pick up code Processing
    PICKUPCREATE            CONSTANT number(1) := 1;
    PICKUPREPLACE           CONSTANT number(1) := 2;
    PICKUPDELETE            CONSTANT number(1) := 3;
    PICKUPNEWGROUP          CONSTANT number(1) := 4;

    PICKUPLONG              CONSTANT number(1) := 1;
    PICKUPSHORT             CONSTANT number(1) := 2;

    EXPORTRATE              CONSTANT number(1) := 1;
    IMPORTRATE              CONSTANT number(1) := 2;

    LOTNOCHANGE             CONSTANT number(1) := 0;
    LOTNEW                  CONSTANT number(1) := 1;
    LOTMODIFIED             CONSTANT number(1) := 2;
    LOTDELETED              CONSTANT number(1) := 3;
    LOTCONFIRMED            CONSTANT number(1) := 4;
    LOTPICKED               CONSTANT number(1) := 5;
    LOTRELEASED             CONSTANT number(1) := 6;
    -- ADD BY MANJUNATH REDDY ON 06-03-08
    LOTCOMPLETE             CONSTANT NUMBER(1) := 7;

--  Audit Trail Type
    BEFOREIMAGE             CONSTANT number(1) := 1;
    AFTERIMAGE              CONSTANT number(1) := 2;


  --  Import / Export Code
    EXPORTCODE              CONSTANT number(8) := 31700001;
    IMPORTCODE              CONSTANT number(8) := 31700002;

--  Reversal Types
    UTILTRADEDEAL           CONSTANT number(1) := 1;
    UTILHEDGEDEAL           CONSTANT number(1) := 2;
    UTILTRADECROSS          CONSTANT number(1) := 3;
    UTILHEDGECROSS          CONSTANT number(1) := 4;
    UTILFCYLOAN             CONSTANT number(1) := 5;
    UTILEXPORTS             CONSTANT number(1) := 6;
    UTILPURCHASED           CONSTANT number(1) := 7;
    UTILCOLLECTION          CONSTANT number(1) := 8;
    UTILIMPORTS             CONSTANT number(1) := 9;
    UTILIMPORTBILL          CONSTANT number(2) := 10;

    UTILCOMMODITYDEAL       CONSTANT number(2) := 11;
    UTILBCRLOAN             CONSTANT number(2) := 12;
    UTILCOVEREDORDERS       CONSTANT number(2) := 13;
----Currency Future
    UTILFUTUREDEAL          CONSTANT number(2) := 14;

    UTILOPTIONHEDGEDEAL     CONSTANT number(2) := 15;
    UTILMUTUALFUND          CONSTANT number(2) := 16;
    UTILFIXEDDEPOSIT        CONSTANT number(2) := 17;
    UTILFDPRECLOSE          CONSTANT number(2) := 18;
    UTILMFSCHEME            CONSTANT number(2) := 19;
    UTILMFTRANSACTION       CONSTANT number(2) := 20;
    UTILCONTRACTOS          CONSTANT NUMBER(2) := 21; --need to be changed in code as 16 was used for MF
    UTILBONDCLOSE           CONSTANT NUMBER(2) := 22;
    UTILUSERUPDATE          CONSTANT NUMBER(2) := 23;
    --IRS
    UTILFRA                 CONSTANT number(2) :=30;    

-- Update the bank statement user refenece no or ibs reference no
   UpdateBankRefNo          Constant number(1) :=1;
   UpdateIBSRefNo           Constant number(1) :=2;

--  Outstanding Amount return type
    AMOUNTFCY               CONSTANT number(1) := 1;
    AMOUNTINR               CONSTANT number(1) := 2;

 --  Interest Link Type
    LINKFIXEDBASE           CONSTANT number(8) := 27900001;
    LINKFIXEDNOBASE         CONSTANT number(8) := 27900002;
    LINKFLOATBASE           CONSTANT number(8) := 27900003;
    LINKFLOATNOBASE         CONSTANT number(8) := 27900004;

--  Interest Days
    DAYS365                 CONSTANT number(8) := 28000001;
    DAYS360                 CONSTANT number(8) := 28000002;

--  Interest Calculation Type
    INTERESTNORMAL          CONSTANT number(8) := 28400001;
    INTERESTDISCOUNT        CONSTANT number(8) := 28400002;
    INTERESTREPO            CONSTANT number(8) := 28400003;

---

    Forward                 Constant number(8) :=  32200001;
    Future                  Constant number(8) :=  32200002;
    Options                 Constant Number(8) :=  32200003;
--	Rates Type Var Analysis
    AvgRates                CONSTANT number(8) := 32200001;
    DayOpenRates            CONSTANT number(8) := 32200002;
    DayEndRates             CONSTANT number(8) := 32200003;
    MaxRates                CONSTANT number(8) := 32200004;
    MinRates                CONSTANT number(8) := 32200005;

--	Rate Types
    BidRates                CONSTANT number(8) :=	32400001;
    AskRates                CONSTANT number(8) :=	32400002;
    MeanRates               CONSTANT number(8) :=	32400003;

    REFMATURITYVALUE        CONSTANT number(4) := 1120;



-- Module Types

   CurrencyModule           CONSTANT number(8) := 29200001;
   MoneyModule              CONSTANT number(8) := 29200001;
   CommdityModule           CONSTANT number(8) := 29200001;
   CurrencyFuturesModule    CONSTANT number(8) := 29200001;
   DerivativesModule        CONSTANT NUMBER(8) := 29200001;
   TBILL                    CONSTANT number(8) := 28100053;   
   COMMERCIALPAPER          CONSTANT NUMBER(8) := 28100054;
   CERTIFICATEOFDEPOSIT     CONSTANT number(8) := 28100055;

 --------Currency Futures
   ForwardContract          CONSTANT number(8) := 32200001;
   FutureContract           CONSTANT number(8) := 32200002;
   OptionContract           CONSTANT number(8) := 32200003;

   ExchangeTraded           CONSTANT number(8) := 32800001;
   OTC                      CONSTANT number(8) := 32800002;
   TOI                      CONSTANT number(1) := 1;
   ALMUS                    CONSTANT number(1) := 2;

--- FORWARDROLLOVER
  SYSFORWARDROLLOVER      CONSTANT NUMBER(8) :=10600063;
--  Global Variable Types
    gvarcompany   NUMBER(1);
    gvarOperation   varchar2(1000);
    gvarMessage     varchar2(1000);
    gvarError       varchar2(2048);
    gnumCode        number(8);
    gnumAmount      number(15,2);
    gClobType       Clob;
    gXMLNode        XMLDom.DOMNode;
    gXMLNodeList    XMLDom.DomNodeList;
    gdocXML         XMLDom.DomDocument;
    gXMLType        XMLType;

--  Global Variables
    gnumCompanyCode number(8);
    gnumDayStatus   number(8);
    gdatToday       date;

    TYPE DataCursor IS REF CURSOR;

--    Function fncReturnWorkday
--            (DayStatus out number)
--            Return Date;

--    Function fncLastDay
--            Return Date;

  Function fncSplitAlpha
        (   InputString in varchar2,
            StringPart in out nocopy varchar2)
    Return number;

    Function fncReturnError
        (   ProcName in varchar2,
            ProcMessage in varchar2,
            RecordSets in number,
            Errornumber in number,
            OperationMessage in varchar2,
            SysMessage in varchar2)
            Return varchar2;

    Function fncReturnError
        (   FuncName in varchar2,
            ErrorNumber in number,
            FuncMessage in varchar2,
            OperationMessage in varchar2,
            SysMessage in varchar2)
            Return varchar2;

    Function fncAddNode
        (   ParentNode in XMLType,
            ChildNode in XMLType,
            NodeName in varchar2,
            ChildTree in varchar2 := Null)
            Return XMLType;

    Function fncSetNodeValue
        (   InputDoc in out nocopy xmlDom.domDocument,
            NodePath in varchar2,
            NodeValue in varchar2)
            Return Number;

    Function fncSetNodeValue
        (   DocNode in out nocopy xmlDom.domNode,
            InputNode in out nocopy xmlDom.domNode,
            NodeValue in varchar2)
            Return Number;

    Function fncGetNodeValue
       (    InputNode in xmlDom.domNode,
            NodePath in varchar2)
            Return varchar2;

    Function fncAddNode
        (   DocDocument in out nocopy xmlDom.domDocument,
            TargetNode in out nocopy xmlDom.domNode,
            NodeName in varchar2,
            NodeValue in varchar2 := NULL)
            Return xmlDom.domNode;


    Function fncRemoveNode
    (   DocDocument in out nocopy xmlDom.domDocument,
        TargetNode in out nocopy xmlDom.domNode,
        nodXML  in xmlDom.domNode)
        Return xmlDom.domNode;

     Function fncAddNode
    (   DocDocument in out nocopy xmlDom.domDocument,
        TargetNode in out nocopy xmlDom.domNode,
        nodXML  in xmlDom.domNode)
        Return xmlDom.domNode;



    Function fncProcessNode
        (   DocNode in out nocopy xmlDom.domNode,
            TargetNode in out nocopy xmlDom.domNode,
            ProcessType in number,
            RowNumber in number)
            Return number;


    Function fncXMLExtract
        ( xmlString in xmlType,
          NodeName in varchar2,
          NodeValue in varchar2,
          InputType in number := 1)
          return varchar2;

    Function fncXMLExtract
        ( xmlString in xmlType,
          NodeName in varchar2,
          NodeValue in number,
          InputType in number := 1)
          return number;

    Function fncXMLExtract
        ( xmlString in xmlType,
          NodeName in varchar2,
          NodeValue in date,
          InputType in number := 1)
          return date;

    Function fncXMLExtract
        ( xmlString in xmlType,
          NodeName in varchar2,
          NodeValue in xmlType,
          InputType in number := 1)
          return xmlType;

    Function fncGenericGet
        ( QueryString in varchar2,
          RowsetTag in varchar2 := 'ROWSET',
          RowTag in varchar2 := 'ROW')
          return xmlType;

    Function fncReturnDomdoc
        ( buf in varchar2)
        Return xmlDom.DomDocument;

    Function fncReturnParam
        ( clbParam in clob,
          varNode in varchar2)
        Return varchar2;

    Function fncReturnParam
        ( docXML in xmldom.DomDocument,
          varNode in varchar2)
        Return varchar2;

    Function fncGenerateSerial
        ( SerialType in number,
          CompanyCode in number := 0)
          return varChar2;

    Function fncWriteTree
        ( TreeRoot in varchar2,
          TreeXPath in varchar2,
          docSource in xmlDom.DomDocument)
          return xmlDom.DomDocument;

    Function fncReturnStatus
        (   InputStatus in number,
            ActionCode in number)
            Return Number;

    Function fncCreateAttrib
        (   docXML in xmldom.DomDocument,
            AttribName in varchar2,
            AttribValue in varchar2)
            Return xmlDom.DOmNode;

    Function fncSetParam
        (   docXML in out Nocopy xmldom.DomDocument,
            NodeName in varchar2,
            NodeValue in varchar2)
            Return number;

    Function fncSetParam
        (   clbXML in out Nocopy clob,
            NodeName in varchar2,
            NodeValue in varchar2)
            Return number;

    Function fncSetParam
        (   xmlString in out Nocopy xmlType,
            NodePath in varchar2,
            NodeValue in varchar2,
            AddNode in Number := 1)
            Return number;

    Procedure prcGenericInsert
        ( ParamData in clob,
          ErrorData out NoCopy clob,
          ProcessData out NoCopy clob);

    Procedure prcGenericEdit
        ( ParamData in clob,
          ErrorData out NoCopy clob,
          ProcessData out NoCopy clob);
--    function fncGetLocalCurrency
--        ( LocationCode in number)
--          return number;




END pkgGlobalMethods;
/