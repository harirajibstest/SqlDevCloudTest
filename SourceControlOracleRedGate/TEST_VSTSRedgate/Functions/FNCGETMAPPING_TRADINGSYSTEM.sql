CREATE OR REPLACE function "TEST_VSTSRedgate".fncGetMapping_Tradingsystem( 
          TradingSystem in number,
          MappingCode in Number,
          SourceValue in varchar) return varchar2
      as 
       varTemp varchar(100);
      begin
          select intf_destination_value
           into varTemp
           from trtran008H 
          where intf_interface_source=TradingSystem
          --and intf_Mapping_code=306
          and INTF_SOURCE_FEED=SourceValue;
      return varTemp;
      exception 
       when no_data_found then
         --varTemp := MappingCode || '99999';
         return varTemp;
      end;
/