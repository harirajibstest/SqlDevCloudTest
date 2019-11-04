CREATE OR REPLACE Function "TEST_VSTSRedgate".fncSubstituteFields1
    (ParamData in Gconst.gClobType%Type,
     EntityName in varchar2,
     InwardOutward in varchar2)
return clob
is
    varEntity           varchar2(30);
    numError            Number;
    varOperation        varchar(4000);
    varMessage          varchar(4000);
    varError            varchar(4000);
    xmlTemp             xmltype;
    clbTemp             clob;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nodInnerTemp        xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodFinal            xmlDom.domNode;
    RootNode            xmlDom.domNode;
    TXTNODE             XMLDOM.DOMTEXT;
    varXPath            varchar2(512);
    nlsTemp             xmlDom.DomNodeList;
    nlsTempInner        xmlDom.DomNodeList;
    nmpTemp             xmldom.domNamedNodeMap;
    ELMXML              XMLDOM.DOMELEMENT;
    numSub              number(5);
    varNodeName         varchar(30);
    varTemp             varchar2(100);
    varNodeValue        varchar(4000);
    numInnerSub         number(5);
    TXTDOM              XMLDOM.DOMTEXT;
Begin
    varMessage := 'Substituting XML Fields to Database Fields';
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := ParamData;
    --varOperation:='
    xmlTemp:=XMLTYPE(ParamData);
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);
    
   -- dbms_lob.createtemporary (clbTempRows,true);
    --clbTempRows := nlsTemp;
    
    varXPath := '//' || EntityName  ;
    RootNode:= xslProcessor.SELECTSINGLENODE(nodFinal,varXPath);
 
    varXPath := '//' || EntityName || '/ROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numSub := xmlDom.getLength(nlsTemp);
    
    for numSub in 1..xmlDom.getLength(nlsTemp)
    Loop
        varOperation := 'Extracting Data';
        nodTemp := xmlDom.Item(nlsTemp, numSub);
        nmpTemp:= xmlDom.getAttributes(nodTemp);
        nodTemp := xmlDom.Item(nmpTemp, 0);
        --xmlDom.writeToClob(nodTemp, clbTemp);
        varXPath :='//' || EntityName ||'/ROW[@NUM="'||numSub || '"]';
       -- VARTEMP := '//' || TRIM(NODENAME) || '/text()';
       -- nlsTempInner := xslProcessor.selectNodes(nodFinal, varXPath);
      
        RootNode:= xslProcessor.SelectSingleNode(nodFinal, varXPath);
        nlsTempInner :=xmlDom.getChildNodes(RootNode);
        for numInnerSub in 0..dbms_xmldom.getLength(nlsTempInner) -1
        loop
       
           nodTemp := xmlDom.Item(nlsTempInner, numInnerSub);
           varNodeName := DBMS_XMLDOM.getNodeName(nodTemp);
            varoperation:='Processign Node ' ||varNodeName;
           VARTEMP:=varXPath || '/' || varNodeName || '/text()';
           begin 
              varNodeValue := xmlTemp.EXTRACT(VARTEMP).GETSTRINGVAL();
           exception
             when others then 
              varNodeValue := null;
           end;
           if  InwardOutward = 'Inward' then               
                 select fldp_column_name 
                   into varTemp
                  from trsystem999
                  where fldp_table_synonym = EntityName
                    and fldp_xml_field=varNodeName;
           end if;
           if  InwardOutward = 'Outward' then
                select fldp_xml_field 
                 into varTemp
                from trsystem999
                where fldp_table_synonym = EntityName
                  and fldp_column_name=varNodeName;
           End if;
            
           
             varOperation := 'Extracting Data';
--            TXTNODE := DBMS_XMLDOM.CREATETEXTNODE(docFinal, varNodeValue);
--            nodInnerTemp := XMLDOM.MAKENODE(TXTNODE);
            ELMXML := xmlDom.CreateElement(docFinal,varTemp); 
            nodInnerTemp := XMLDOM.MAKENODE(ELMXML);
            nodInnerTemp:=DBMS_XMLDOM.AppendCHILD(RootNode, nodInnerTemp);
            
            TXTDOM := XMLDOM.CREATETEXTNODE(docFinal, varNodeValue);
            nodTemp1 := XMLDOM.MAKENODE(TXTDOM);
            nodInnerTemp := XMLDOM.APPENDCHILD(nodInnerTemp, nodTemp1);
            
           -- XMLDOM.SETNODEVALUE(nodInnerTemp, varNodeValue);
            
            
            nodTemp:=XMLDOM.REMOVECHILD(nodTemp, nodTemp);
        end loop;
    end loop;

    DBMS_LOB.CREATETEMPORARY (clbTemp,  TRUE);
    XMLDOM.WRITETOCLOB(docFinal, clbTemp);
    dbms_output.put_line(clbTemp);
    return clbTemp;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('AuditTrail', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return clbTemp;
End fncSubstituteFields1;
/