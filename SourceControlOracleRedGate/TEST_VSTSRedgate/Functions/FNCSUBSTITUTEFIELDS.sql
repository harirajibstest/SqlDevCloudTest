CREATE OR REPLACE Function "TEST_VSTSRedgate".fncSubstituteFields
    (ParamData in Gconst.gClobType%Type,
     EntityName in varchar2,
     InwardOutward in varchar2)
return clob
is
    varEntity           varchar2(30);
    numError            Number;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    xmlTemp             GConst.gXMLType%Type;
    xmlTemp1            GConst.gXMLType%Type;
    clbTemp             Gconst.gClobType%Type;
    nodTemp             xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodFinal            xmlDom.domNode;
    docChild            xmlDom.domDocument;
    nodRoot1            xmlDom.domNode;
    RootNode            xmlDom.domNode;
    varXPath            varchar2(512);
    nlsTemp             xmlDom.DomNodeList;
    nmpTemp             xmldom.domNamedNodeMap;
    numSub              number(5);
Begin
    varMessage := 'Substituting XML Fields to Database Fields';
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := ParamData;
    xmlTemp:=XMLTYPE(ParamData);
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);
    varXPath:= '//CommandSet'; 
    RootNode:= xslProcessor.SELECTSINGLENODE(nodFinal,varXPath);
    
    varXPath := '//' || EntityName || '/ROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numSub := xmlDom.getLength(nlsTemp);
    
    for numSub in 0..xmlDom.getLength(nlsTemp) -1
    Loop
        varOperation := 'Extracting Data';
        nodTemp := xmlDom.Item(nlsTemp, numSub);
        nmpTemp:= xmlDom.getAttributes(nodTemp);
        nodTemp := xmlDom.Item(nmpTemp, 0);
        xmlDom.writeToClob(nodTemp, clbTemp);
        
        for curFields in
        (select fldp_xml_field, fldp_column_name
            from trsystem999
            where fldp_table_synonym = EntityName)
         Loop
            if  InwardOutward = 'Inward' then               
                  clbTemp := replace(clbTemp, curFields.fldp_xml_field ,curFields.fldp_column_name );         
            end if;
            if  InwardOutward = 'Outward' then
                clbTemp := replace(clbTemp,curFields.fldp_column_name , curFields.fldp_xml_field );
            End if; 
         End Loop;
         xmlTemp1:=XMLTYPE(clbTemp);
         docChild := xmlDom.newDomDocument(xmlTemp1);
         nodRoot1 := xmlDom.makeNode(docChild);
    
         --xmlTemp1:=XMLTYPE(clbTemp);
         RootNode := XMLDOM.APPENDCHILD(nodRoot1, RootNode);   
    end loop;
    xmlDom.writetoClob(docFinal , clbTemp);
    
end fncSubstituteFields;
/