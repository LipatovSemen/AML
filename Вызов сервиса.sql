declare vRES varchar2(200);
        pOBJID varchar2(12);
begin
pOBJID := aml_seq.NEXTVAL;
sdm$send_aml_req(pi_name=> 'ЕРМАКОВ ЕВГЕНИЙ ПЕТРОВИЧ'
               , pi_inn=> ''
               , pi_series=> ''
               , pi_number=> ''
               , pi_birthdate=> ''
               , vobjid=>pOBJID
               , vsubj_id=> null
               , po_id=> vRES);
    
end;




           select * from GC.SDM$AML_CHECK_LOG L
                        ,GC.SDM$AML_CHECK_RES R 
           WHERE 1=1
             AND L.OBJID = (SELECT MAX(LL.OBJID) FROM GC.SDM$AML_CHECK_LOG LL)
             AND R.OBJID(+)= L.OBJID
