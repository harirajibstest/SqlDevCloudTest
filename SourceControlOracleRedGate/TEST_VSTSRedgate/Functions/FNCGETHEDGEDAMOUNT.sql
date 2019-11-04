CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCGETHEDGEDAMOUNT" ( TradeReference in varchar2, TradeSerial in number, ReversalType in number,CoverOverdue in number,
                                                AmountType in number,AsonDate in Date, DealReference in varchar2,srno in number )
      return Number
      as
        numOutstanding  Number(15,2);
        numLoanAmount   number(15,2);
        numDealAmount   number(15,2);
        numHedgedAmount number(15,2);
        
      begin
        select PKGFOREXPROCESS.fncGetOutstanding(TradeReference,0,ReversalType, AmountType, AsonDate) into numOutstanding from dual;
        
        Select nvl(sum(hedg_hedged_fcy),0) into numDealAmount
        from trtran004
        where hedg_trade_reference = TradeReference
        and hedg_record_status between 10200001 and 10200004;
        
        select nvl(sum(LOLN_ADJUSTED_FCY),0) into numLoanAmount 
        from trtran010,trtran005 
        where LOLN_TRADE_REFERENCE = TradeReference
        and LOLN_LOAN_NUMBER = FCLN_LOAN_NUMBER
        and LOLN_RECORD_STATUS not in  (10200005,10200006);
        
--        select pkgforexprocess.fncGetOutstanding(null,0,CoverOverdue,AmountType, AsonDate,TradeReference) into numDealAmount from dual;
        if Srno = 1 then ---For Coverd all amount include Loan and Deals
            numHedgedAmount :=  (numLoanAmount + numDealAmount) ;
        elsif Srno = 2 then -- Only Loan amount 
            numHedgedAmount :=  numLoanAmount  ;
        elsif Srno = 3 then--Deal Linked amount
            numHedgedAmount := numDealAmount;
        end if;
        return numHedgedAmount;
        Exception
          when others then
          numHedgedAmount := 0;
       return numHedgedAmount;
 end fncGetHedgedamount;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/