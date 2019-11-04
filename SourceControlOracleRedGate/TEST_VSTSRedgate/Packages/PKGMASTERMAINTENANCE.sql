CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGMASTERMAINTENANCE" 

    is
--  Created on 19/03/2007
--  Last Modified on 19/03/2007

Function fncBuildQuery
    (   ParamData   in  Gconst.gClobType%Type)
    return varchar2;
Function forwardSettlement
    (   RecordDetail in GConst.gClobType%Type)return number; 


--Function fncInsertDeals
--    ( AsonDate in Date)
--    return number;
--
--Function fncGetRate
--    ( CurrencyCode in Number,
--      ForCurrency in Number,
--      AsonDate in Date,
--      BidAsk in Number,
--      RateType in varchar2 := 'spot',
--      DueDate in Date := null)
--      Return Number;
--
--Function fncHoldingRate
--    ( CurrencyCode in Number,
--      AsonDate in Date,
--      ErrorNumber in out nocopy number)
--    return number;
--
--Function fncCalculateRate
--    ( AsonDate in Date)
--    return number;
Function fncCurrentAccount
    (RecordDetail in clob)
    return number;

Function fncCurrentAccount
    (   RecordDetail in GConst.gClobType%Type,
        ErrorNumber  in out  nocopy number)
    return clob;

Function fncCompleteUtilization
    (   ReferenceNumber in varchar2,
        ReferenceType in number,
        WorkDate in date,
        SerialNumber in number default 1)
    return number;
Function fncMiscellaneousUpdates
    (   RecordDetail in GConst.gClobType%Type,
        EditType in number,
        ErrorNumber in out nocopy number)
    return clob;

Procedure prcProcessPickup
              ( PickDetails in Clob,
                PickField in varchar2,
                PickValue out nocopy varchar2);

Procedure prcCoordinator
        (   ParamData   in  Gconst.gClobType%Type,
            ErrorData   out NoCopy Gconst.gClobType%Type,
            ProcessData out NoCopy Gconst.gClobType%Type,
            GenCursor   out Gconst.DataCursor,
            NextCursor  out Gconst.DataCursor,
            CursorNo3   out Gconst.DataCursor,
            CursorNo4   out Gconst.DataCursor,
            CursorNo5   out Gconst.DataCursor,
            Cursorno6   out Gconst.DataCursor);
Function fncSubstituteFields
    (ParamData in Gconst.gClobType%Type,
     EntityName in varchar2,
     InwardOutward in varchar2)
return clob;
 Function fncMasterMaintenance
    (   MasterDetail in GConst.gClobType%Type,
        ErrorNumber in out nocopy number)
    return clob;

--Function fncCurrentAccount
--    (   RecordDetail in GConst.gClobType%Type,
--        ErrorNumber in out nocopy number)
--    return clob;
End; -- Package spec
/