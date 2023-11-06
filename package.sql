-- Start of DDL Script for Package GC.AML
-- Generated 06-ноя-2023 17:28:03 from GC@BANK

CREATE OR REPLACE 
package aml is

  PROCEDURE add_param(pi_params          in out varchar2,
                      pi_parameter_name  varchar2,
                      pi_parameter_value varchar2);
                      
                  

  FUNCTION get_params(pi_params varchar2) return params_array;

  PROCEDURE call(pi_template_id   VARCHAR2,
                 pi_params        VARCHAR2,
                 vObjid           VARCHAR2,
                 vSubj_id         VARCHAR2,
                 po_params        OUT VARCHAR2,
                 po_data_response OUT VARCHAR2);
                 

  PROCEDURE sdm$send_aml_req(PI_NAME       VARCHAR2,
                             PI_INN        VARCHAR2,
                             PI_SERIES     VARCHAR2,
                             PI_NUMBER     VARCHAR2,
                             PI_BIRTHDATE  VARCHAR2,
                             vOBJID        VARCHAR2,
                             vSUBJ_ID      VARCHAR2,
                             PO_ID     OUT VARCHAR2);
                             
  PROCEDURE sdm$send_aml_req_subj(vSUBJ_ID VARCHAR2);                                     
                 
  PROCEDURE proc_res(vOBJID varchar2);    
end aml;
/



-- End of DDL Script for Package GC.AML

