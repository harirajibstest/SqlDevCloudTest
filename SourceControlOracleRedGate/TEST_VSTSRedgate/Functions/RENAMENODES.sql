CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."RENAMENODES" (ParamData  in  Gconst.gClobType%Type,varEntity in varchar2,filedsType in number) RETURN xmlDom.domnode AS
 
--varEntity1          varchar2(30);
--filedsType1         number(1);
xmlcurrent          xmlDom.domNode;
xmlParent           xmlDom.domNode;
nodFinal            xmlDom.domNode;
docFinal            xmlDom.domDocument;
nlsTemp             xmlDom.domNodeList;

varXPath            varchar2(30);
varXml              varchar(50);
varField            varchar(50);
varnodeValue        varchar(100);
varnodeName         varchar(50);

nodXML              xmlDom.domNode;
nodXML1             xmlDom.domNode;
txtDom              xmlDom.domText;
xmlTemp             GConst.gXMLType%Type;
     
BEGIN
--
-- varEntity1 := GConst.fncXMLExtract(xmlType(ParamData), 'Entity', varEntity);
-- filedsType1 := gconst.fncxmlextract(xmltype(ParamData),   'Type',   filedsType);
 
  docFinal := xmlDom.newDomDocument(xmltype(ParamData));
  nodFinal := xmlDom.makeNode(docFinal);
  xmlTemp  := xmlType(ParamData);
  varXPath := '//' || varEntity || '/ROW[@NUM]';
  nlsTemp  := xslProcessor.selectNodes(nodFinal, varXPath);
  --xmlDoc :=  
  For curFields in
   (select fldp_column_name, fldp_xml_field, 
       fldp_key_no, fldp_data_type
       from trsystem999
       where fldp_table_synonym = varEntity
       order by fldp_column_id)
       
 Loop
      varField:= curFields.fldp_column_name;
      varXml:= curFields.fldp_xml_field;
      if (filedsType=Gconst.FieldToXML) then
        varXPath := '//' || varEntity || '/ROW[@NUM]' || '/' || varField;
        varnodeName  := varField;        
      else
        varXPath := '//' || varEntity || '/ROW[@NUM]' || '/' || varXml;
        varnodeName  := varField;     
      end if;
        xmlcurrent := xslProcessor.selectSingleNode(nodFinal, varXPath);
        varnodeValue := gconst.fncGetNodeValue(xmlcurrent,varXPath);
        xmlParent :=XMLDOM.getparentnode(xmlcurrent);
        xmlParent := gconst.fncAddNode(docFinal,xmlParent, varnodeName,varnodeValue);
     --   xmldom.removeChild(xmlTemp,xmlcurrent);
     
  end Loop; 
  return (xmlcurrent);
END RenameNodes;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/