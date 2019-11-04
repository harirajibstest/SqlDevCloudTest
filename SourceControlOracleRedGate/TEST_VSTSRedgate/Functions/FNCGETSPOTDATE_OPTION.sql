CREATE OR REPLACE Function "TEST_VSTSRedgate".fncGetSpotDate_Option
    ( CounterParty in number,
      AsonDate in Date,
      srNum in Number)
      return Date
      is
--  Created on 28/05/08
    numError      number;
    numFlag       number(1);
    numCount      number(2) := 0;
    datReturn     date;
    datTemp       date;
    varOperation  gconst.gvaroperation%type;
    varMessage    gconst.gvarmessage%type;
    varError      gconst.gvarerror%type;
Begin
    varMessage := 'Returning Spot Due Date for ' || AsonDate;
    datReturn := null;
    varMessage := 'Extracting Settelment Date';
    SELECT HDAY_CALENDAR_DATE into datTemp
    FROM
      (SELECT ROW_NUMBER() OVER( ORDER BY HDAY_CALENDAR_DATE DESC) ROWNUMBER ,
        HDAY_CALENDAR_DATE
      FROM TRSYSTEM001
      WHERE HDAY_LOCATION_CODE =30299999
      AND HDAY_DAY_STATUS NOT IN (26400008,26400009,26400007)
      AND HDAY_CALENDAR_DATE  <= AsonDate
      ) Holidays
    WHERE Holidays.Rownumber = 1;

    IF srNum = 1 THEN
      datReturn := datTemp;
    ELSE
      SELECT HDAY_CALENDAR_DATE into datReturn
      FROM
        (SELECT ROW_NUMBER() OVER( ORDER BY HDAY_CALENDAR_DATE DESC) ROWNUMBER ,
          HDAY_CALENDAR_DATE
        FROM TRSYSTEM001
        WHERE HDAY_LOCATION_CODE =30299999
        AND HDAY_DAY_STATUS NOT IN (26400008,26400009,26400007)
        AND HDAY_CALENDAR_DATE  <= datTemp
        ) Holidays
      WHERE Holidays.Rownumber = 3;  
    END IF;
--    if SubDays = 0 then
--      datTemp := AsonDate - 2;
--    else
--      datTemp := AsonDate - SubDays;
--    end if;
--    
--    SELECT NVL(COUNT(*),0)
--      INTO numCount
--    FROM trsystem001
--    WHERE HDAY_CALENDAR_DATE BETWEEN datTemp AND AsonDate
--      AND hday_location_code in
--      (select nvl(lbnk_bank_location, 0)
--        from trmaster306
--        where lbnk_pick_code = Counterparty
--        and hday_day_status NOT IN
--        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2));
--    IF numCount > 1 THEN
--      SELECT MAX(HDAY_CALENDAR_DATE)
--        INTO datReturn
--      FROM trsystem001
--      WHERE HDAY_CALENDAR_DATE <= datTemp
--      AND hday_location_code in
--      (select nvl(lbnk_bank_location, 0)
--        from trmaster306
--        where lbnk_pick_code = Counterparty
--        and hday_day_status NOT IN
--        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2));
--    ELSE
--     select decode(trim(to_char(datTemp , 'DAY')),
--        'SATURDAY', datTemp - 2,
--        'SUNDAY', datTemp - 3)
--        into datTemp
--        from dual;
--
--
--    numFlag := 0;
--
--    varOperation := 'Extracting Holidays for the counter Party';
--    for curHoliday in
--    (select distinct hday_calendar_date
--      from trsystem001
--      where hday_location_code in
--      (select nvl(lbnk_bank_location, 0)
--        from trmaster306
--        where lbnk_pick_code = Counterparty
--        and hday_day_status in
--        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2)
--       union
--       select nvl(lbnk_corr_location,0)
--        from trmaster306
--        where lbnk_pick_code = CounterParty
--        and hday_day_status in
--        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2))
--      and hday_calendar_date <= datTemp
--      order by hday_calendar_date desc)
--    Loop
--      numFlag := 1;
--
--      if  curHoliday.hday_calendar_date < datTemp then
--        datReturn := datTemp;
--        exit;
--      else
--        datTemp := datTemp - 1;
--      end if;
--
--    End Loop;
--
--    if numFlag = 0 then -- No Holiday records after the date
--      select decode(trim(to_char(AsonDate - 2, 'DAY')),
--        'SATURDAY', AsonDate - 3,
--        'SUNDAY', AsonDate - 4,
--        AsonDate - 2)
--        into datReturn
--        from dual;
--    End if;
--    END IF;
--
    return datReturn;
Exception
    when others then
      varerror := 'SpotDueDate: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      return datReturn;
End fncGetSpotDate_Option;
 
 
 
 
/