-- Start of DDL Script for Package Body GC.AML
-- Generated 06-ноя-2023 17:28:48 from GC@BANK

CREATE OR REPLACE 
package body aml is

  procedure add_param(pi_params          in out varchar2,
                      pi_parameter_name  varchar2,
                      pi_parameter_value varchar2) is
  begin
    pi_params := pi_params || '|' || pi_parameter_name || '={' ||
                 pi_parameter_value || '}';
  
    if substr(pi_params, 1, 1) = '|' then
      pi_params := substr(pi_params, 2);
    end if;
  end;


  function get_params(pi_params varchar2) return params_array is
    v_array  params_array := params_array();
    v_params varchar2(32767) := pi_params;
    v_name   varchar2(32767);
    v_value  varchar2(32767);
  begin
    while v_params is not null and instr(v_params, '=') > 0 and
          instr(v_params, '{') > 0 and instr(v_params, '}') > 0 loop
      v_name  := substr(v_params, 1, instr(v_params, '=') - 1);
      v_value := substr(v_params,
                        instr(v_params, '={') + 2,
                        instr(v_params, '}') - length(v_name) - 3);
    
      v_array.EXTEND;
      v_array(v_array.LAST) := params_record(v_name, v_value);
    
      v_params := replace(v_params, v_name || '={' || v_value || '}');
    
      if substr(v_params, 1, 1) = '|' then
        v_params := substr(v_params, 2);
      end if;
    
    end loop;
    dbms_output.put_line(v_params);    
    return v_array;
  end;

  FUNCTION generate_xml(pi_template_id VARCHAR2, pi_params VARCHAR2)
    RETURN VARCHAR2 IS
    v_template       VARCHAR2(32767);
    v_request_params VARCHAR2(32767);
    v_params         VARCHAR2(32767);
  BEGIN
    SELECT template_xml, request_params
      INTO v_template, v_request_params
      FROM gc.sdm_aml_template
     WHERE template_id = pi_template_id
       and status = 1;
  
    if v_request_params is not null then
      v_params := v_request_params || '|' || pi_params;
    else
      v_params := pi_params;
    end if;
  
    for a in (select * from table(aml.get_params(v_params))) loop
      v_template := REPLACE(v_template,
                            '%' || upper(a.parameter_name) || '%',
                            a.parameter_value);
    end loop;
    RETURN v_template;
  END;

  PROCEDURE send(pi_url           IN VARCHAR2,
                 po_data_request  IN VARCHAR2,
                 vObjid           IN VARCHAR2,
                 po_data_response IN OUT VARCHAR2) IS
    V_SOAP_REQUEST      XMLTYPE := XMLTYPE(po_data_request);
    V_SOAP_REQUEST_TEXT CLOB := V_SOAP_REQUEST.getClobVal();
    V_REQUEST           UTL_HTTP.REQ;
    V_RESPONSE          UTL_HTTP.RESP;
    V_BUFFER            VARCHAR2(1024);
    RES_XML             VARCHAR2(4000);
  BEGIN
  
    --V_REQUEST := UTL_HTTP.BEGIN_REQUEST( pi_url, 'POST','HTTP/1.1');
    --  V_REQUEST := UTL_HTTP.BEGIN_REQUEST(URL => pi_url, METHOD => 'POST');
        dbms_output.put_line('еще работает');
   V_REQUEST :=UTL_HTTP.begin_request(pi_url, 'POST', ' HTTP/1.1');
         dbms_output.put_line('еще работает');
   UTL_HTTP.set_header (V_REQUEST, 'Accept-Encoding', 'gzip,deflate');
   utl_http.set_header (V_REQUEST, 'Content-Type', 'text/xml;charset=windows-1251'); 
   UTL_HTTP.set_header (V_REQUEST, 'Content-Length', length(po_data_request));
   UTL_HTTP.set_header (V_REQUEST, 'Host', 'localhost:3038');
   UTL_HTTP.set_header (V_REQUEST, 'Connection', 'Keep-Alive');
   UTL_HTTP.set_header (V_REQUEST, 'User-Agent', 'Apache-HttpClient/4.1.1 (java 1.5)');
     
    UTL_HTTP.WRITE_TEXT(R => V_REQUEST, DATA => V_SOAP_REQUEST_TEXT);
     
    V_RESPONSE := UTL_HTTP.GET_RESPONSE(V_REQUEST);
   
    dbms_output.put_line('еще работает');

    UTL_HTTP.read_text(V_RESPONSE, res_xml);
    dbms_output.put_line(res_xml);
    UPDATE GC.SDM$AML_CHECK_LOG
    SET XML_RESPONSE = RES_XML
    WHERE OBJID = vOBJID;
    --COMMIT;
    UTL_HTTP.END_RESPONSE(V_RESPONSE);

  EXCEPTION
    WHEN UTL_HTTP.END_OF_BODY THEN
      UTL_HTTP.END_RESPONSE(V_RESPONSE);
    WHEN OTHERS THEN
    dbms_output.put_line('Ошибка111');
      UTL_HTTP.END_RESPONSE(V_RESPONSE);
    
  END;

  PROCEDURE call(pi_template_id   VARCHAR2,
                 pi_params        VARCHAR2,
                 vObjid           VARCHAR2,
                 vSubj_id         VARCHAR2,
                 po_params        OUT VARCHAR2,
                 po_data_response OUT VARCHAR2) IS
    v_xml          VARCHAR2(32767);
    v_url          VARCHAR2(32767);
    v_retval       NUMBER;
    v_retmsg       VARCHAR2(32767);
    v_start        TIMESTAMP;
    v_end          TIMESTAMP;
    v_execute_time NUMBER;
  BEGIN
  
    SELECT SYSTIMESTAMP INTO v_start FROM DUAL;
  

           
  
    v_xml := generate_xml(pi_template_id, pi_params);

INSERT INTO SDM$AML_CHECK_LOG
      (OBJID,
       SUBJ_ID,
       EVENT_TIME,
       XML_REQUEST,
       REQUEST_PARAMS)
    VALUES
      (vOBJID,
       vSUBJ_ID,
       SYSTIMESTAMP,
       v_xml,
       pi_params);
    --COMMIT;             
  dbms_output.put_line(v_xml);
    SELECT url
      INTO v_url
      FROM gc.sdm_aml_server
     WHERE server_id = (SELECT server_id
                          FROM gc.sdm_aml_template
                         WHERE template_id = pi_template_id)
       and status = 1;
  
    send(v_url, v_xml, vobjid, po_data_response);
    --po_params := generate_result(pi_template_id, po_data_response);
    SELECT SYSTIMESTAMP INTO v_end FROM DUAL;
    SELECT EXTRACT(MINUTE FROM diff) * 60 + EXTRACT(SECOND FROM diff) seconds
      INTO v_execute_time
      FROM (SELECT v_end - v_start diff FROM DUAL);
  
    v_retval := 1;
    v_retmsg := 'Success';
  
      UPDATE GC.SDM$AML_CHECK_LOG
      SET RETVAL = v_retval
         ,RETMSG = v_retmsg
         ,EXECUTE_TIME = v_execute_time
      WHERE OBJID = vObjid;
      proc_res(vOBJID);
  EXCEPTION
    WHEN OTHERS THEN
      v_retval := -1;
      v_retmsg := DBMS_UTILITY.format_error_backtrace() || SQLERRM;
      UPDATE GC.SDM$AML_CHECK_LOG
      SET RETVAL = v_retval
         ,RETMSG = v_retmsg
         ,EXECUTE_TIME = v_execute_time
      WHERE OBJID = vObjid;
  END;
  
  PROCEDURE sdm$send_aml_req(PI_NAME   VARCHAR2,
                           PI_INN VARCHAR2,
                           PI_SERIES  VARCHAR2,
                           PI_NUMBER  VARCHAR2,
                           PI_BIRTHDATE  VARCHAR2,
                           vOBJID VARCHAR2,
                           vSUBJ_ID VARCHAR2,
                           PO_ID     OUT VARCHAR2) IS
  v_template_id     VARCHAR2(100) := 'GetInfoType';
  v_data_response   VARCHAR2(4000);
  v_request_params  VARCHAR2(4000);
  v_response_params VARCHAR2(4000);
BEGIN

-- Формирования строки параметров необходимой для отправки --
  aml.add_param(v_request_params, 'NAME', PI_NAME);
  aml.add_param(v_request_params, 'INN', PI_INN);
  aml.add_param(v_request_params, 'SERIES', PI_SERIES);
  aml.add_param(v_request_params, 'NUMBER', PI_NUMBER);
  aml.add_param(v_request_params, 'BIRTHDATE', PI_BIRTHDATE);

-- Вызов основной процедуры --
  aml.call(v_template_id,
          v_request_params,
          vOBJID,
          vSUBJ_ID,
          v_response_params,
          v_data_response);
-- Извлечение необходимого параметра из результирующей строки параметров --
--  PO_ID := ws.get_param(v_response_params, 'UnreliableRefTypeName');

END;

PROCEDURE sdm$send_aml_req_subj(vSUBJ_ID VARCHAR2) is
        vRES varchar2(200);
        pOBJID varchar2(12);
        vNAME varchar2(200);
        vINN varchar2(20);
        vSeries varchar2(50);
        vNumber varchar2(50);
        vBirthDate varchar2(20);        
BEGIN
pOBJID := gc.aml_seq.NEXTVAL;

SELECT S.NAME
      ,H.RNN
      ,TO_CHAR(H.BIRTHDAY,'DD.MM.YYYY')
      ,DECODE(CP.PASSPORTCODE,'8',SUBSTR(REPLACE(CP.SERNUM,' ',''),1,4),TRIM(CP.SERNUM))
      ,DECODE(CP.PASSPORTCODE,'8',SUBSTR(REPLACE(CP.SERNUM,' ',''),5,6),TRIM(CP.SERNUM))  
INTO vNAME 
    ,vINN
    ,vBirthDate
    ,vSeries
    ,vNumber
FROM GC.SUBJ S
    ,GC.HUMAN H 
    ,GC.CLIENTPASSPORT CP 
    ,GC.PASSPORT P
WHERE S.ID = vSUBJ_ID
  AND H.SUBJ_ID (+)= S.ID
  AND CP.SUBJ_ID(+)= S.ID
  AND P.CODE(+)=CP.PASSPORTCODE
          
             AND P.PRIORITET=(SELECT MIN(PP.PRIORITET) 
                  FROM GC.SUBJ SS,GC.CLIENTPASSPORT CPP,GC.PASSPORT PP 
                  WHERE SS.ID=vSUBJ_ID  --- СВЯЗКА С ID КЛИЕНТА (SUBJ.ID) 
                              AND CPP.SUBJ_ID=SS.ID AND CPP.PASSPORTCODE=PP.CODE) ;



sdm$send_aml_req(pi_name=> vNAME
               , pi_inn=> vINN
               , pi_series=> vSeries
               , pi_number=> vNumber
               , pi_birthdate=> vBirthDate
               , vobjid=>pOBJID
               , vsubj_id=> vSUBJ_ID
               , po_id=> vRES);
    
end; 
 
  PROCEDURE PROC_RES (vOBJID VARCHAR2) IS
  vTEX VARCHAR2(2000);
  vP int;
  vPB int;
  vPE int;
  Len int;
  vStr varchar2(200);
  Begin
  FOR I IN
  (
  SELECT to_char(g.xml_response.getClobVal()) as RES 
     FROM GC.SDM$AML_CHECK_LOG G
  WHERE OBJID = vOBJID     
  )
  LOOP
  vP:=instr(i.RES,'ns3:TOTALCOUNT');
  dbms_output.put_line(vP);
  vPB:=instr(i.Res,'>',vP)+1;
    dbms_output.put_line(vPB);
  vPE:=instr(i.Res,'<',vP);
    dbms_output.put_line(vPE);
  Len:=vPE-vPB;

  vStr := substr(i.Res,vPB,Len);
    dbms_output.put_line(vStr);  
  
  UPDATE GC.SDM$AML_CHECK_LOG
  SET RESPONSE_COUNT = vSTR
  WHERE OBJID = vOBJID;
  --COMMIT;
  
  IF i.RES like '%UnreliableRefType>1<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'1','Перечень организаций и ФЛ, в отношении которых имеются сведения об их причастности к экстремистской деятельности или терроризму');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>2<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'2','OFAC');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>3<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'3','Альтернативный справочник ИПДЛ');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>4<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'4','Справочник "Белый список"');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>5<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'5','Справочник "Черный список"');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>6<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'6','Альтернативный справочник "Список неблагонадежных клиентов"');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>7<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'7','Неисполнительные участники ВЭД');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>8<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'8','Справочник "Утрата связи с ЮЛ"');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>9<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'9','Список недействительных российских паспортов');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>10<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'10','Стратегическая организация');
  --COMMIT;
  END IF;

  IF i.RES like '%UnreliableRefType>11<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'11','Список кредитных организаций, зарегистрированных на территории Российской Федерации');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>12<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'12','Сведения о ликвидированных и ликвидируемых юридических лицах (ЛИКВЮЛ)');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>13<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'13','Перечень кредитных организаций, соответствующих требованиям Закона №213-ФЗ');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>14<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'14','Список BadGuys (Юридические лица)');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>15<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'15','CтопЛист');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>16<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'16','Список нежелательных НКО');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>17<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'17','Банкроты(ЮЛ)');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>18<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'18','Банкроты (физическое лицо)');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>19<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'19','BadGuys (Физические лица)');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>20<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'20','Стратегические предприятия');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>21<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'21','Перечень организаций и физических лиц, в отношении которых имеются сведения об их причастности к распространению оружия массового уничтожения ЮЛ');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>22<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'22','Перечень организаций и физических лиц, в отношении которых имеются сведения об их причастности к распространению оружия массового уничтожения ФЛ');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>23<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'23','Список санкционных лиц Украина ФЛ"');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>24<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'24','Список санкционных лиц Украина ЮЛ');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>25<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'25','Северная Корея. Дипломаты');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>29<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'29','ЗСК - уровни риска');
  --COMMIT;
  END IF;  
  
  IF i.RES like '%UnreliableRefType>-15<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-15','Список "Сводный санкционный перечень Совета Безопасности ООН"');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>-18<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-18','Справочник "EU Embagro list"');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>-19<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-19','Список Dow Jones');
  --COMMIT;
  END IF;
  
  IF i.RES like '%UnreliableRefType>-20<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-20','Сведения о лицах со случаями отказов');
  --COMMIT;
  END IF;    
  
  IF i.RES like '%UnreliableRefType>-21<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-21','Список решений Межведомственной комиссии');
  --COMMIT;
  END IF;    
  
  IF i.RES like '%UnreliableRefType>-22<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-22','Перечень организаций и физических лиц, в отношении которых имеются сведения об их причастности к распространению оружия массового уничтожения');
  --COMMIT;
  END IF;    
  
  IF i.RES like '%UnreliableRefType>-23<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-23','ФинЦерт');
  --COMMIT;
  END IF;    
  
  IF i.RES like '%UnreliableRefType>-26<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-26','ФТС');
  --COMMIT;
  END IF;   
  
  IF i.RES like '%UnreliableRefType>-33<%' THEN
  INSERT INTO GC.SDM$AML_CHECK_RES
  (OBJID,TYPE_SPRAV,TEXT)
  VALUES (vOBJID,'-33','Контур Призма');
  --COMMIT;
  END IF;                                               
  
  
  END LOOP;
    EXCEPTION WHEN OTHERS THEN
      UPDATE GC.SDM$AML_CHECK_LOG
      SET RESPONSE_COUNT = 0
      WHERE OBJID = vObjid;
  
  END;

end AML;
/



-- End of DDL Script for Package Body GC.AML

