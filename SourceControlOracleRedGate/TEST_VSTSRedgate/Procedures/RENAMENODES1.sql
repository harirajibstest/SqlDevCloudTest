CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."RENAMENODES1" (ParamData  in  Gconst.gClobType%Type,varEntity in varchar2,filedsType in number,clbTemp out NoCopy xmltype )is
 
--varEntity1          varchar2(30);
--filedsType1         number(1);
xmlcurrent          xmlDom.domNode;
xmlParent           xmlDom.domNode;
nodTemp             xmldom.domnode;
nodTemp1            xmldom.domnode;
nodFinal            xmlDom.domNode;
docFinal            xmlDom.domDocument;
nlsTemp             xmlDom.domNodeList;

varXPath            varchar2(100);
varXml              varchar(50);
varField            varchar(50);
varCovtNodeName     varchar(100);
varnodeValue        varchar(100);
varnodeName         varchar(50);

numSub              number(2);
numtemp             number(3);
nodXML              xmlDom.domNode;
nodXML1             xmlDom.domNode;
txtDom              xmlDom.domText;
xmlTemp             GConst.gXMLType%Type;
elmXML              xmldom.DOMElement;
nmpTemp             xmldom.domNamedNodeMap;
varCase             varchar2(20);
varlength           varchar2(20);
varformat           varchar2(20);
vartooltip          varchar2(100);
vardefault          varchar(50);
vardaterange        varchar2(10);
boolrownum          boolean;
BEGIN
--
-- varEntity1 := GConst.fncXMLExtract(xmlType(ParamData), 'Entity', varEntity);
-- filedsType1 := gconst.fncxmlextract(xmltype(ParamData),   'Type',   filedsType);
 
  docFinal := xmlDom.newDomDocument(xmltype(ParamData));
  nodFinal := xmlDom.makeNode(docFinal);
  xmlTemp  := xmlType(ParamData);
  varXPath := '//' || varEntity || '/ROW[@NUM]';
  nlsTemp  := xslProcessor.selectNodes(nodFinal, varXPath);
  if (xmlDom.getLength(nlsTemp)=0) then
    boolrownum:=false; 
    varXPath := '//' || varEntity || '/ROW';
    nlsTemp  := xslProcessor.selectNodes(nodFinal, varXPath);
  else 
    boolrownum:=true; 
  end if;
  for numSub in 0..xmlDom.getLength(nlsTemp) -1
  Loop
  
      For curFields in
       (select fldp_column_name, fldp_xml_field, 
           fldp_key_no, fldp_data_type,FLDP_TEXT_CASE,FLDP_TEXT_LENGTH,FLDP_TEXT_FORMAT,FLDP_TOOLTIP_TEXT,FLDP_DEFAULT_VALUE,FLDP_DATE_RANGE
           from trsystem999
           where fldp_table_synonym = varEntity
           order by fldp_column_id)
      Loop
          varField:= curFields.fldp_column_name;
          varXml:= curFields.fldp_xml_field;
    
         if (filedsType=gconst.XmlField) then
            varcase:=curFields.FLDP_TEXT_CASE;
            varlength :=curFields.FLDP_TEXT_LENGTH;
            varformat := curFields.FLDP_TEXT_FORMAT;
            vartooltip  := curFields.FLDP_TOOLTIP_TEXT;
            vardefault  := curFields.FLDP_DEFAULT_VALUE;
            vardaterange  := curFields.FLDP_DATE_RANGE;
            varnodeName:= curFields.fldp_xml_field;
            varXPath := '//' || varEntity || '/ROW';
            xmlParent := xslProcessor.selectSingleNode(nodFinal, varXPath);
            insert into temp values(varXPath,varnodeName);
            commit;
            elmXML :=xmlDom.CreateElement(docFinal, varnodeName);
            if varcase is not null then
                xmlDom.setAttribute(elmXML,'TestCase',varcase);
            end if;
            if varlength is not null then
                xmlDom.setAttribute(elmXML,'Length',varlength);
            end if;
            if varformat is not null then
               xmlDom.setAttribute(elmXML,'Format',varformat);
            end if;
            if vartooltip is not null then
              xmlDom.setAttribute(elmXML,'Tooltip',vartooltip);
            end if;
            if vardefault is not null then
              xmlDom.setAttribute(elmXML,'Default',vardefault);
            end if;
            if vardaterange is not null then
              xmlDom.setAttribute(elmXML,'Daterange',vardaterange);
            end if;
            xmlcurrent:=xmldom.makeNode(elmXML);
            nodTemp:=gconst.fncAddNode(docFinal,xmlParent,xmlcurrent);
    
 --           if ( boolrownum=false) then
 --               varXPath := '//' || varEntity || '/ROW' || '/' || varField;
 --           else
 --               nodTemp := xmlDom.item(nlsTemp, numSub);
 --               nmpTemp := xmlDom.getAttributes(nodTemp);
 --               nodTemp1 := xmlDom.item(nmpTemp, 0);
 --               numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
                
 --               varXPath := '//' || varEntity || '/ROW[@NUM="' || numTemp || '"]' || '/' || varField;    
 --           end if;
--            varnodeName  := varXml;        
--            xmlcurrent := xslProcessor.selectSingleNode(nodFinal, varXPath);
--            varnodeValue := gconst.fncGetNodeValue(xmlcurrent,varXPath);
--            xmlParent :=XMLDOM.getparentnode(xmlcurrent);
--            nodTemp := gconst.fncAddNode(docFinal, xmlParent,varnodeName,varnodeValue);
--            nodTemp :=gconst.fncRemoveNode(docFinal,xmlParent,xmlcurrent);
    
          else
            if (filedsType=gconst.XMLToField) then
                varnodeName  := varXml;  
                varCovtNodeName:=varField;
            elsif (filedsType=gconst.FieldToXML) then     
                varnodeName  := varField;
                varCovtNodeName:=varXml;
            end if;
            if ( boolrownum=false) then
                varXPath := '//' || varEntity || '/ROW' || '/' || varnodeName;
            else
                nodTemp := xmlDom.item(nlsTemp, numSub);
                nmpTemp := xmlDom.getAttributes(nodTemp);
                nodTemp1 := xmlDom.item(nmpTemp, 0);
                numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
                varXPath := '//' || varEntity || '/ROW[@NUM="' || numTemp || '"]' || '/' || varnodeName;    
            end if;
            --varXPath := '//' || varEntity || '/ROW[@NUM]' || '/' || varXml;
            
            xmlcurrent := xslProcessor.selectSingleNode(nodFinal, varXPath);
            varnodeValue := gconst.fncGetNodeValue(xmlcurrent,varXPath);
            xmlParent :=XMLDOM.getparentnode(xmlcurrent);
            nodTemp := gconst.fncAddNode(docFinal, xmlParent,varCovtNodeName,varnodeValue);
            nodTemp :=gconst.fncRemoveNode(docFinal,xmlParent,xmlcurrent);
         end if;
          
  end Loop; 
  end loop;
     clbTemp :=xmldom.GETXMLTYPE(docFinal);
    
   --clbTemp := xmlParent.GetClobVal();
   
   -- xmlTemp.GetClobVal();
  --return (xmlcurrent);
 -- Exception
 --   When others then
       
END RenameNodes1;
/