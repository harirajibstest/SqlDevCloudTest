CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCDEALPROFILE1" (WhereClause in varchar2)
      return number as
--Created by TMM on 20/10/2012      
-- Input Parameter is dummy since the function cannot be called
-- with a blank signature
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numFlag             number(1);
    numMonth            number(2);
    numSerial           number(5);
    numCurrency         number(2);
    numCurrencyCode     number(8);
    numForCurrency      number(8);
    numType             number(8);
    DateStart           Date;
    sqlQuery            varchar2(4000);
    qryTemp             varchar2(4000);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    Type                    DealProfile is varray(13) of number;
    DealCount              DealProfile; 
    DealIntraDay          DealProfile;
    DealPositional        DealProfile;
    DealPosPL              DealProfile;
    DealIntPL              DealProfile;
    DealIntPve          DealProfile;
    DealPosPve          DealProfile;
    DealIntNve          DealProfile;
    DealPosNve          DealProfile;
    DealTemp            DealProfile;
    
    Type currencyPairs  is varray(20) of trsystem980%RowType;
    curPair             currencyPairs;
    Type Deal_Cursor    is Ref Cursor;    
    dealCursor          Deal_Cursor;
    Cursor curDealDetail is
    select DealNumber, DealDate, CancelDate, PandLFcy, 
      transcode, status, exrate, maturity,companycode, bankcode, 
      userid, hedgetrade, currency, 32200001 DealType    
      from vewForwards;
    curDeals  curDealDetail%RowType;
Begin
    varMessage := 'Creating Deal Profile for ' || fncToday();
    numError := 0;
    numCurrency := 1;
    numFlag := -1;
    DateStart := fncToday();
    
    curpair := currencyPairs();
    
    if  to_char(DateStart, 'MM') in ('01','02','03') then
      DateStart := to_date('01-APR-' ||  to_char(to_number(to_char(DateStart, 'YYYY')) - 1));
    else
      DateStart := to_date('01-APR-' || to_char(DateStart, 'YYYY'));
    End if;
--fncToday(),0,'a','b',0,0,0,0,0,0,0,0,0,0,0,0,0        
    curPair := currencyPairs();
    DealCount := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealTemp := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealIntraDay:= DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealPositional:= DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealPosPL := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealIntPL:= DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealIntPve := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealPosPve := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealIntNve := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealPosNve := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    Delete from trsystem980;
    
    varOperation := 'Consolidating Deal Details';

    qryTemp :=   
    'with tabDeals as
    (select DealNumber,DealDate,CancelDate,PandLFcy,transcode,status,exrate, 
      maturity,companycode,bankcode,userid,hedgetrade,currency,32200001 DealType    
      from vewForwards
      union
    select DealNumber,DealDate,CancelDate,PandLFcy,transcode,status,exrate, 
      maturity,companycode,bankcode,userid,hedgetrade,currency,32200002 DealType    
      from vewFutures
      union
    select DealNumber,DealDate,CancelDate,PandLFcy,transcode,status,greatest(bc,bp,sc,sp) exrate, 
      maturity,companycode,bankcode,userid,hedgetrade,currency,32200003 DealType    
      from vewOptions) select * from tabDeals ';
    sqlQuery := qryTemp || replace(WhereClause, 'greatest(bc,bp,sc,sp)', 'exrate');
--    sqlQuery := 'select DealNumber, DealDate, CancelDate, PandLFcy from vewForwards';

--delete from temp;
--insert into temp(tt) values (SqlQuery);
--commit;

    Open dealCursor for sqlQuery;
    Loop
      Fetch dealCursor into curDeals;
      Exit when dealCursor%NotFound;

      numMonth := to_number(to_char(curDeals.DealDate,'MM'));
      DealCount(numMonth) := DealCount(numMonth) + 1;
  
      if curDeals.DealDate = curDeals.CancelDate then
        DealIntraday(numMonth) := DealIntraday(numMonth) + 1;

        if curDeals.PandLFcy > 0 then
          DealIntPL(numMonth) := DealIntPL(numMonth) + 1; 
          DealIntPve(numMonth) :=  DealIntPve(numMonth) + curDeals.PandLFcy;
        else
          DealIntNve(numMonth) :=  DealIntNve(numMonth) + curDeals.PandLFcy *-1;
        End if;                

      else
        DealPositional(numMonth) := DealPositional(numMonth) + 1; 

        if curDeals.PandLFcy > 0 then
          DealPosPL(numMonth) := DealPosPL(numMonth) + 1; 
          DealPosPve(numMonth) := DealPosPve(numMonth) + curDeals.PandLFcy;
        else
          DealPosNve(numMonth) := DealPosNve(numMonth) + curDeals.PandLFcy * -1;
        End if;                
        
      End if;

      numFlag := 1;

      for numSerial in 1..curPair.Count
      Loop
        if curPair(numSerial).deal_profile_currency = curDeals.currency then
          numCurrency := numSerial;
          numFlag := 0;        
          Exit;
        End if;
      End Loop;


      if numFlag = 1 then
        curPair.Extend;
        numCurrency := curPair.Count;
        curPair(numCurrency).deal_profile_currency := curDeals.currency;
        curPair(numCurrency).deal_profile_date := fncToday();
        curPair(numCurrency).deal_Profile_serial := numCurrency + 20;
        curPair(numCurrency).deal_profile_january := 0;
        curPair(numCurrency).deal_profile_february := 0;
        curPair(numCurrency).deal_profile_march := 0;
        curPair(numCurrency).deal_profile_april := 0;
        curPair(numCurrency).deal_profile_may := 0;
        curPair(numCurrency).deal_profile_june := 0;
        curPair(numCurrency).deal_profile_july := 0;
        curPair(numCurrency).deal_profile_august := 0;
        curPair(numCurrency).deal_profile_september := 0;
        curPair(numCurrency).deal_profile_october := 0;
        curPair(numCurrency).deal_profile_november := 0;
        curPair(numCurrency).deal_profile_december := 0;
        curPair(numCurrency).deal_profile_total := 0;
      End if;

      
      case 
      when numMonth = 1 then curPair(numCurrency).deal_profile_january := 
          curPair(numCurrency).deal_profile_january + curDeals.PandLFcy;
      when numMonth = 2 then curPair(numCurrency).deal_profile_february := 
          curPair(numCurrency).deal_profile_february + curDeals.PandLFcy;
      when numMonth = 3 then curPair(numCurrency).deal_profile_march := 
          curPair(numCurrency).deal_profile_march + curDeals.PandLFcy;
      when numMonth = 4 then curPair(numCurrency).deal_profile_april := 
          curPair(numCurrency).deal_profile_april + curDeals.PandLFcy;
      when numMonth = 5 then curPair(numCurrency).deal_profile_may := 
          curPair(numCurrency).deal_profile_may + curDeals.PandLFcy;
      when numMonth = 6 then curPair(numCurrency).deal_profile_june := 
          curPair(numCurrency).deal_profile_june + curDeals.PandLFcy;
      when numMonth = 7 then curPair(numCurrency).deal_profile_july := 
          curPair(numCurrency).deal_profile_july + curDeals.PandLFcy;
      when numMonth = 8 then curPair(numCurrency).deal_profile_august := 
          curPair(numCurrency).deal_profile_august + curDeals.PandLFcy;
      when numMonth = 9 then curPair(numCurrency).deal_profile_september := 
          curPair(numCurrency).deal_profile_september + curDeals.PandLFcy;
      when numMonth = 10 then curPair(numCurrency).deal_profile_october := 
          curPair(numCurrency).deal_profile_october + curDeals.PandLFcy;
      when numMonth = 11 then curPair(numCurrency).deal_profile_november := 
          curPair(numCurrency).deal_profile_november + curDeals.PandLFcy;
      when numMonth = 12 then curPair(numCurrency).deal_profile_december := 
          curPair(numCurrency).deal_profile_december + curDeals.PandLFcy;
      else 
        NULL;
      end case;      
      curPair(numCurrency).deal_profile_total := 
          curPair(numCurrency).deal_profile_total + curDeals.PandLFcy;
    End Loop;
   
   For numSerial in 1..12
   Loop
    DealCount(13) := DealCount(13) + DealCount(numSerial);
    DealIntraDay(13) := DealIntraDay(13) + DealIntraDay(numSerial); 
    DealPositional(13) := DealPositional(13) + DealPositional(numSerial);
    DealPosPL(13) := DealPosPL(13) + DealPosPL(numSerial);
    DealIntPL(13) :=  DealIntPL(13) +  DealIntPL(numSerial);
    DealIntPve(13) := DealIntPve(13) + DealIntPve(numSerial);
    DealPosPve(13) := DealPosPve(13) + DealPosPve(numSerial);
    DealIntNve(13) := DealIntNve(13) + DealIntNve(numSerial);
    DealPosNve(13) := DealPosNve(13) + DealPosNve(numSerial);
   End Loop;
   
   varOperation := 'Inserting Trade Deal Count'; 
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 1, 'Total No of Trades', 'All Pairs',
    DealCount(4), DealCount(5), DealCount(6), DealCount(7),
    DealCount(8), DealCount(9), DealCount(10), DealCount(11),
    DealCount(12), DealCount(1), DealCount(2), DealCount(3),DealCount(13));
   
   varOperation := 'Inserting Successful Trades';
   For numSerial in 1..13 
   Loop
    DealTemp(numSerial) := DealIntPL(numSerial) + DealPosPL(numSerial);
   End Loop;
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 2, 'Total Success Deals', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));
    
   varOperation := 'Inserting Successful Ratio';
   For numSerial in 1..13
   Loop
    if  DealTemp(numSerial) > 0 and DealCount(numSerial) > 0 then
      DealTemp(numSerial) := Round((DealTemp(numSerial) * 100) / DealCount(numSerial));
    End if;      
   End Loop;
    
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 3, 'Total Success Ratio %', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));

   varOperation := 'Inserting Intra Deal Count';
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 4, 'Total Intra Day Deals', 'All Pairs',
    DealIntraDay(4), DealIntraDay(5), DealIntraDay(6), DealIntraDay(7),
    DealIntraDay(8), DealIntraDay(9), DealIntraDay(10), DealIntraDay(11),
    DealIntraDay(12), DealIntraDay(1), DealIntraDay(2), DealIntraDay(3),DealIntraDay(13));
   
   varOperation := 'Inserting Intra Deal Ratio';
   For numSerial in 1..13 
   Loop
    DealTemp(numSerial) := 0;
    if DealIntraDay(numSerial) > 0 and DealCount(numSerial) > 0 then
      DealTemp(numSerial) := Round((DealIntraDay(numSerial) * 100) / DealCount(numSerial));
    End if;      
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 5, 'Intra Day Ratio %', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));
    
   varOperation := 'Inserting Intra Deal Success Ratio %';
   For numSerial in 1..13 
   Loop
    DealTemp(numSerial) := DealIntraday(numSerial);
-- The above statement changed on 11/09/13 - Samir's mail dt 14/08/13    
--    DealTemp(numSerial) := DealIntPl(numSerial) + DealPosPL(numSerial); -- Total Success
    if DealTemp(numSerial) > 0 and DealIntPL(numSerial) > 0 then
      DealTemp(numSerial) := Round((DealIntPl(numSerial) * 100) / DealTemp(numSerial));
    End if;      
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 6, 'Intra Day Success Ratio %', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));
   
   varOperation := 'Inserting Positional Deal Count';
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 7, 'Total Positional Deals', 'All Pairs',
    DealPositional(4), DealPositional(5), DealPositional(6), DealPositional(7),
    DealPositional(8), DealPositional(9), DealPositional(10), DealPositional(11),
    DealPositional(12), DealPositional(1), DealPositional(2), DealPositional(3),DealPositional(13));
   
   varOperation := 'Inserting Positional Deal Ratio';
   For numSerial in 1..13 
   Loop
    DealTemp(numSerial) := 0;
    if DealPositional(numSerial) > 0 and DealCount(numSerial) > 0 then
      DealTemp(numSerial) := Round((DealPositional(numSerial) * 100) / DealCount(numSerial));
    End if;
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 8, 'Positional Ratio %', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));
    
   varOperation := 'Inserting Positional Deal Succes Ratio %';
   For numSerial in 1..13 
   Loop
    DealTemp(numSerial) := DealPositional(numSerial);
-- The above statement changed on 11/09/13 - Samir's mail dt 14/08/13    
    --DealIntPl(numSerial) + DealPosPL(numSerial); -- Total Success
    if DealTemp(numSerial) > 0 and DealPosPL(numSerial) > 0 then
      DealTemp(numSerial) := Round((DealPosPl(numSerial) * 100) / DealTemp(numSerial));
    End if;      
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 9, 'Positional Success Ratio%', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));

   varOperation := 'Inserting Average +ve Trade Profit & Loss';
   For numSerial in 1..13
   Loop
    DealTemp(numSerial) := DealIntPve(numSerial) + DealPosPve(numSerial); -- +ve Amount Total
    if DealTemp(numSerial) > 0 and (DealIntPL(numSerial) + DealPosPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealTemp(numSerial) / 
                          (DealIntPL(numSerial) + DealPosPL(numSerial))); -- Avg +ve Total
    End if;                          
   End Loop;
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 10, 'Avg / +ve Trade (Total)', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));

   varOperation := 'Inserting Average -ve Trade Profit & Loss';
   For numSerial in 1..13
   Loop
    DealTemp(numSerial) := DealIntNve(numSerial) + DealPosNve(numSerial); -- +ve Amount Total
      if DealTemp(numSerial) > 0 and (DealIntPL(numSerial) + DealPosPL(numSerial))> 0 then
        DealTemp(numSerial) := Round(DealTemp(numSerial) / (DealCount(numSerial) - 
                          (DealIntPL(numSerial) + DealPosPL(numSerial)))); -- Avg +ve Total
      End if;                          
   End Loop;
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 11, 'Avg / -ve Trade (Total)', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));

   varOperation := 'Inserting Average +ve IntraDay Profit & Loss';
   for numSerial in 1..13
   loop
    if DealIntPve(numSerial) > 0 and (DealIntraDay(numSerial)- DealIntPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealIntPve(numSerial) / 
                (DealIntraDay(numSerial)- DealIntPL(numSerial)));
    End if;                
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 12, 'Avg / +ve IntraDay', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));

   varOperation := 'Inserting Average -ve IntraDay Profit & Loss';
   for numSerial in 1..13
   loop
    if DealIntNve(numSerial) > 0 and (DealIntraDay(numSerial)- DealIntPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealIntNve(numSerial) / 
                (DealIntraDay(numSerial)- DealIntPL(numSerial)));
    End if;                
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 13, 'Avg / -ve IntraDay', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));
----
   varOperation := 'Inserting Average +ve Positional Profit & Loss';
   for numSerial in 1..13
   loop
    if DealPosPve(numSerial) > 0 and (DealPositional(numSerial)- DealPosPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealPosPve(numSerial) / 
                (DealPositional(numSerial)- DealPosPL(numSerial)));
    End if;                
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 14, 'Avg / +ve Positional', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));

   varOperation := 'Inserting Average -ve Positional Profit & Loss';
   for numSerial in 1..13
   loop
    if DealPosNve(numSerial) > 0 and (DealPositional(numSerial)- DealPosPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealposNve(numSerial) / 
                (Dealpositional(numSerial)- DealPosPL(numSerial)));
    End if;                
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total)
    values(fncToday(), 15, 'Avg / -ve Positional', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),DealTemp(13));

   varOperation := 'Inserting Currency Pair wise P & L'; 
   
   for numSerial in 1..curPair.Count
   Loop
     insert into trsystem980
     (deal_profile_date,deal_profile_serial, deal_profile_legend,
      deal_profile_currency,deal_profile_april,deal_profile_may,
      deal_profile_june,deal_profile_july,deal_profile_august,
      deal_profile_september,deal_profile_october,deal_profile_november,
      deal_profile_december,deal_profile_january,deal_profile_february,
      deal_profile_march,deal_profile_total)
     values (curPair(numSerial).deal_profile_date,curPair(numSerial).deal_profile_serial, 
      curPair(numSerial).deal_profile_legend,curPair(numSerial).deal_profile_currency,
      curPair(numSerial).deal_profile_april,curPair(numSerial).deal_profile_may,
      curPair(numSerial).deal_profile_june,curPair(numSerial).deal_profile_july,
      curPair(numSerial).deal_profile_august,curPair(numSerial).deal_profile_september,
      curPair(numSerial).deal_profile_october,curPair(numSerial).deal_profile_november,
      curPair(numSerial).deal_profile_december,curPair(numSerial).deal_profile_january,
      curPair(numSerial).deal_profile_february,curPair(numSerial).deal_profile_march,
      curPair(numSerial).deal_profile_total);
  End Loop;
  
  COMMIT;
  return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('DealProfile1', numError, varMessage, 
                      varOperation, varError);
      ROLLBACK;                      
      raise_application_error(-20101, varError);                      
      return numError;
End fncDealProfile1;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/