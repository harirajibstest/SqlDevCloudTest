CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCCHECKTHEODER" (TradeReference Varchar) return Varchar 
as 
 Reversereference Varchar(50);
 RReference Varchar(50);
Begin 
   Reversereference := TradeReference;
   Rreference:= Tradereference;
    WHILE (Rreference is not null)
    Loop
      Reversereference:=Rreference;
      Select Trad_Reverse_Reference Reversereference
         into Rreference    
        From Trtran002
        Where Trad_Trade_Reference=Rreference;
    End Loop;  
    Return Reversereference;
end;
 
 
 
 
 
 
 
 
 
/