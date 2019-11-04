CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGFUNCTIONS" as

function fncsum( num1 number, num2 number) return number;
function fncproduct ( argument1 number , argument2  number) return number;
function fncdate ( Admissiondate  date) return date;
function fncdynamic( arguments varchar2) return number;
function fncevaluate(vararguments  varchar2 ) return varchar2;
function fncbracecheck(arguments varchar2) return number;
function fncApplyRates(mtmrate in number,scenariorate in number ,datWorkDate in date) RETURN number;
function fncGetLocalbankCode(     /*pickkeyvalue in number,*/  descriptiontype in varchar2)  return number ;
function fncgetpayment(uploaddt date, contractno varchar2) return number;

end PKGFUNCTIONS ;
 
 
 
 
 
 
 
 
 
 
/