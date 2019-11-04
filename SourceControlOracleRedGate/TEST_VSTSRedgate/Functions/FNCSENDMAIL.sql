CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCSENDMAIL" return number as

numSeril    number;
begin
 UTL_MAIL.SEND(SENDER     =>  'chandrakomme@gmail.com',
                RECIPIENTS => 'ishwarachandra@ibsfintech.com' ,
                CC         => 'ishwarachandra@ibsfintech.com' ,
                BCC        => '',
                SUBJECT    => 'TEST mail',
                Message    => 'Dev Server Test mail' ) ; 
                
return numSeril;
end fncSendMail;
/