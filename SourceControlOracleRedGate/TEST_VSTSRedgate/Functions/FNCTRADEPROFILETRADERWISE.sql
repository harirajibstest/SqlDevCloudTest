CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCTRADEPROFILETRADERWISE" 
        ( UserID in varchar2, 
          TraderCode in Number, 
          DateStart in Date, 
          AsonDate in Date)
      return number as
--Created by TMM on 20/10/2012      
-- Input Parameter is dummy since the function cannot be called
-- with a blank signature
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numMonth            number(2);
    numSerial           number(5);
    numCurrencyCode     number(8);
    numForCurrency      number(8);
    numType             number(8);
--    DateStart           Date;
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
    DealRRPve           DealProfile;
    DealRRNve           DealProfile;
    
Begin
    varMessage := 'Creating Deal Profile for ' || AsonDate;
    numError := 0;
    --DateStart := AsOnDate;
    
    
--    if  to_char(DateStart, 'MM') in ('01','02','03') then
--      DateStart := to_date('01-APR-' ||  to_char(to_number(to_char(DateStart, 'YYYY')) - 1));
--    else
--      DateStart := to_date('01-APR-' || to_char(DateStart, 'YYYY'));
--    End if;
    
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
    DealRRPve := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);
    DealRRNve := DealProfile(0,0,0,0,0,0,0,0,0,0,0,0,0);

    
    varOperation := 'Consolidating Deal Details';
    For Curdeals In
    (select DealNumber, DealDate, CancelDate, ProfitLoss
      from vewCancelDeals
      where HedgeTrade = 26000002
      And CancelDate Between Datestart And Asondate
      and Trader = TraderCode
      and companycode In (Select Usco_Company_Code From Trsystem022a Where Usco_User_Id = UserID))
    Loop
      numMonth := to_number(to_char(curDeals.CancelDate,'MM'));
      DealCount(numMonth) := DealCount(numMonth) + 1;
  
      if curDeals.DealDate = curDeals.CancelDate then
        DealIntraday(numMonth) := DealIntraday(numMonth) + 1;

        if curDeals.ProfitLoss > 0 then
          DealIntPL(numMonth) := DealIntPL(numMonth) + 1; 
          DealIntPve(numMonth) :=  DealIntPve(numMonth) + curDeals.ProfitLoss;
        else
          DealIntNve(numMonth) :=  DealIntNve(numMonth) + curDeals.ProfitLoss *-1;
        End if;                

      else
        DealPositional(numMonth) := DealPositional(numMonth) + 1; 

        if curDeals.ProfitLoss > 0 then
          DealPosPL(numMonth) := DealPosPL(numMonth) + 1; 
          DealPosPve(numMonth) := DealPosPve(numMonth) + curDeals.ProfitLoss;
        else
          DealPosNve(numMonth) := DealPosNve(numMonth) + curDeals.ProfitLoss * -1;
        End if;                
        
      End if;

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
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 1, 'Total No of Trades', 'All Pairs',
    DealCount(4), DealCount(5), DealCount(6), DealCount(7),
    DealCount(8), DealCount(9), DealCount(10), DealCount(11),
    DealCount(12), DealCount(1), DealCount(2), DealCount(3),
    DealCount(13), TraderCode);
   
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
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 2, 'Total Success Deals', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);
    
   varOperation := 'Inserting Successful Ratio';
   For numSerial in 1..13
   Loop
    if  DealTemp(numSerial) > 0 and DealCount(numSerial) > 0 then
      DealTemp(numSerial) := Round((DealTemp(numSerial) * 100) / DealCount(numSerial));
    else
      DealTemp(numSerial) := 0;
    End if;      
   End Loop;
    
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 3, 'Total Success Ratio %', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Intra Deal Count';
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total, deal_trader_code)
    values(AsonDate, 4, 'Total Intra Day Deals', 'All Pairs',
    DealIntraDay(4), DealIntraDay(5), DealIntraDay(6), DealIntraDay(7),
    DealIntraDay(8), DealIntraDay(9), DealIntraDay(10), DealIntraDay(11),
    DealIntraDay(12), DealIntraDay(1), DealIntraDay(2), DealIntraDay(3),
    DealIntraDay(13), TraderCode);
   
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
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 5, 'Intra Day Ratio %', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);
    
   varOperation := 'Inserting Intra Deal Success Ratio %';
   For numSerial in 1..13 
   Loop
    DealTemp(numSerial) := DealIntraday(numSerial);
-- The above statement changed on 11/09/13 - Samir's mail dt 14/08/13    
--    DealTemp(numSerial) := DealIntPl(numSerial) + DealPosPL(numSerial); -- Total Success
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
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 6, 'Intra Day Success Ratio %', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);
   
   varOperation := 'Inserting Positional Deal Count';
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 7, 'Total Positional Deals', 'All Pairs',
    DealPositional(4), DealPositional(5), DealPositional(6), DealPositional(7),
    DealPositional(8), DealPositional(9), DealPositional(10), DealPositional(11),
    DealPositional(12), DealPositional(1), DealPositional(2), DealPositional(3),
    DealPositional(13), TraderCode);
   
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
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 8, 'Positional Ratio %', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);
    
   varOperation := 'Inserting Positional Deal Succes Ratio %';
   For numSerial in 1..13 
   Loop
    DealTemp(numSerial) := DealPositional(numSerial);
-- The above statement changed on 11/09/13 - Samir's mail dt 14/08/13    
--    DealTemp(numSerial) := DealIntPl(numSerial) + DealPosPL(numSerial); -- Total Success
--    DealTemp(numSerial) := DealIntPl(numSerial) + DealPosPL(numSerial); -- Total Success
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
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 9, 'Positional Success Ratio%', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Average +ve Trade Profit';
   For numSerial in 1..13
   Loop
    DealTemp(numSerial) := DealIntPve(numSerial) + DealPosPve(numSerial); -- +ve Amount Total
    if DealTemp(numSerial) > 0 and (DealIntPL(numSerial) + DealPosPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealTemp(numSerial) / 
                          (DealIntPL(numSerial) + DealPosPL(numSerial))); -- Avg +ve Total
      DealRRPve(numSerial) := DealTemp(numSerial);                           
    End if;                          
   End Loop;
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 10, 'Avg / +ve Trade (Total)', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Average -ve Trade Profit ';
   For numSerial in 1..13
   Loop
    DealTemp(numSerial) := DealIntNve(numSerial) + DealPosNve(numSerial); -- +ve Amount Total
      if DealTemp(numSerial) > 0 and (DealIntPL(numSerial) + DealPosPL(numSerial))> 0 then
        DealTemp(numSerial) := Round(DealTemp(numSerial) / (DealCount(numSerial) - 
                          (DealIntPL(numSerial) + DealPosPL(numSerial)))); -- Avg +ve Total
        DealRRNve(numSerial) := DealTemp(numSerial);                          
      End if;                          
   End Loop;
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 11, 'Avg / -ve Trade (Total)', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Risk Reward Ratio (Total)';
   for numSerial in 1..13
   Loop
    if DealRRPve(numSerial) > 0 and DealRRNve(numSerial) > 0 then
      DealTemp(numSerial) := DealRRPve(numSerial) / DealRRNve(numSerial);
    else
      DealTemp(numSerial) := 0;
    End if;      
   End Loop;
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 12, 'RR Ratio Trade (Total)', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13),TraderCode);

   varOperation := 'Inserting Average +ve IntraDay Profit ';
   for numSerial in 1..13
   loop
    DealTemp(numSerial) := 0;
    DealRRPve(numSerial) := 0;
   
    if DealIntPve(numSerial) > 0 and (DealIntraDay(numSerial)- DealIntPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealIntPve(numSerial) / 
                (DealIntraDay(numSerial)- DealIntPL(numSerial)));
      DealRRPve(numSerial) := DealTemp(numSerial);                
    End if;                
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 13, 'Avg / +ve IntraDay', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Average -ve IntraDay Profit ';
   for numSerial in 1..13
   loop
    DealTemp(numSerial) := 0;
    DealRRNve(numSerial) := 0;
    if DealIntNve(numSerial) > 0 and (DealIntraDay(numSerial)- DealIntPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealIntNve(numSerial) / 
                (DealIntraDay(numSerial)- DealIntPL(numSerial)));
      DealRRNve(numSerial) := DealTemp(numSerial);
    End if;                
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 14, 'Avg / -ve IntraDay', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Risk Reward Ratio (IntraDay)';
   for numSerial in 1..13
   Loop
    if DealRRPve(numSerial) > 0 and DealRRNve(numSerial) > 0 then
      DealTemp(numSerial) := DealRRPve(numSerial) / DealRRNve(numSerial);
    else
      DealTemp(numSerial) := 0;
    End if;      
   End Loop;
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 15, 'RR Ratio (IntraDay)', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Average +ve Positional Profit ';
   for numSerial in 1..13
   loop
    DealTemp(numSerial) := 0;
    DealRRPve(numSerial) := 0;
    if DealPosPve(numSerial) > 0 and (DealPositional(numSerial)- DealPosPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealPosPve(numSerial) / 
                (DealPositional(numSerial)- DealPosPL(numSerial)));
      DealRRPve(numSerial) := DealTemp(numSerial);                
    End if;                
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 16, 'Avg / +ve Positional', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Average -ve Positional Profit ';
   for numSerial in 1..13
   loop
    DealTemp(numSerial) := 0;
    DealRRNve(numSerial) := 0;
    if DealPosNve(numSerial) > 0 and (DealPositional(numSerial)- DealPosPL(numSerial)) > 0 then
      DealTemp(numSerial) := Round(DealposNve(numSerial) / 
                (Dealpositional(numSerial)- DealPosPL(numSerial)));
      DealRRNve(numSerial) := DealTemp(numSerial);                                
    End if;                
   End Loop;

   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 17, 'Avg / -ve Positional', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);


   varOperation := 'Inserting Risk Reward Ratio (Positional)';
   for numSerial in 1..13
   Loop
    if DealRRPve(numSerial) > 0 and DealRRNve(numSerial) > 0 then
      DealTemp(numSerial) := DealRRPve(numSerial) / DealRRNve(numSerial);
    else
      DealTemp(numSerial) := 0;
    End if;      
   End Loop;
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
    values(AsonDate, 18, 'RR Ratio (Positional)', 'All Pairs',
    DealTemp(4), DealTemp(5), DealTemp(6), DealTemp(7),
    DealTemp(8), DealTemp(9), DealTemp(10), DealTemp(11),
    DealTemp(12), DealTemp(1), DealTemp(2), DealTemp(3),
    DealTemp(13), TraderCode);

   varOperation := 'Inserting Currency Pair wise P/L '; 
   
   insert into trsystem980
   (deal_profile_date,deal_profile_serial, deal_profile_legend,
    deal_profile_currency,deal_profile_april,deal_profile_may,
    deal_profile_june,deal_profile_july,deal_profile_august,
    deal_profile_september,deal_profile_october,deal_profile_november,
    deal_profile_december,deal_profile_january,deal_profile_february,
    deal_profile_march,deal_profile_total,deal_trader_code)
   with tabDeals as
   (select DealNumber, pkgReturnCursor.fncGetDescription(BaseCurrency,2) || '/' ||
      pkgReturnCursor.fncGetDescription(OtherCurrency,2) Currency,
      CancelDate DealDate, ProfitLoss pandlfcy
      from vewCancelDeals
      where HedgeTrade = 26000002
      And CancelDate Between Datestart And Asondate
      and Trader = TraderCode
      and companycode In (Select Usco_Company_Code From Trsystem022a Where Usco_User_Id = UserID))
   select AsonDate, 21, 'Currency Pairs', Currency,
     sum(decode(to_char(dealdate,'MM'), '04', pandlfcy, 0)) Apr,
     sum(decode(to_char(dealdate,'MM'), '05', pandlfcy, 0)) May,
     sum(decode(to_char(dealdate,'MM'), '06', pandlfcy, 0)) Jun,
     sum(decode(to_char(dealdate,'MM'), '07', pandlfcy, 0)) Jul,
     sum(decode(to_char(dealdate,'MM'), '08', pandlfcy, 0)) Aug,
     sum(decode(to_char(dealdate,'MM'), '09', pandlfcy, 0)) Sep,
     sum(decode(to_char(dealdate,'MM'), '10', pandlfcy, 0)) Oct,
     sum(decode(to_char(dealdate,'MM'), '11', pandlfcy, 0)) Nov,
     sum(decode(to_char(dealdate,'MM'), '12', pandlfcy, 0)) "Dec",
     sum(decode(to_char(dealdate,'MM'), '01', pandlfcy, 0)) Jan,
     sum(decode(to_char(dealdate,'MM'), '02', pandlfcy, 0)) Feb,
     Sum(Decode(To_Char(Dealdate,'MM'), '03', Pandlfcy, 0)) Mar,
     sum(Pandlfcy), TraderCode
     from tabDeals
     group by AsonDate, 21, 'CurrencyPairs',currency;

  COMMIT;
  return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := varOperation || ' : ' || SQLERRM;
      varError := GConst.fncReturnError('DealProfile', numError, varMessage, 
                      varOperation, varError);
      ROLLBACK;                      
      raise_application_error(-20101, varError);                      
      return numError;
END FNCTRADEPROFILETRADERWISE;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/