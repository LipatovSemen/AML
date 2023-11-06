CREATE TYPE PARAMS_RECORD IS OBJECT
(
   parameter_name VARCHAR2 (100),
   parameter_value VARCHAR2 (100)
);


CREATE TYPE PARAMS_ARRAY IS TABLE OF PARAMS_RECORD;
     
CREATE TABLE SDM_AML_SERVER
(
   SERVER_ID   VARCHAR2 (32 BYTE),
   URL         VARCHAR2 (128 BYTE) NOT NULL,
   STATUS      NUMBER DEFAULT 1 NOT NULL,
   CONSTRAINT SDM_AML_SERVER_PK PRIMARY KEY (SERVER_ID)
);



CREATE TABLE SDM_AML_TEMPLATE
(
   TEMPLATE_ID      VARCHAR2 (32 BYTE),
   TEMPLATE_XML     VARCHAR2 (4000 BYTE) NOT NULL,
   SERVER_ID        VARCHAR2 (4000 BYTE),
   REQUEST_PARAMS   VARCHAR2 (4000 BYTE),
   RESPONSE_PARAMS  VARCHAR2 (4000 BYTE),
   XMLNS            VARCHAR2 (4000 BYTE),
   PATH    			VARCHAR2 (4000 BYTE),
   STATUS           VARCHAR2 (10 BYTE) DEFAULT 1,
   CONSTRAINT SDM_AML_TEMPLATE_PK PRIMARY KEY (TEMPLATE_ID),
   CONSTRAINT SDM_AML_TEMPLATE_FK FOREIGN KEY
      (SERVER_ID)
       REFERENCES SDM_AML_SERVER (SERVER_ID)
);

CREATE TABLE SDM$AML_CHECK_LOG
(
   OBJID            VARCHAR2(12),
   SUBJ_ID          VARCHAR2(12),
   EVENT_TIME       TIMESTAMP (6),
   XML_REQUEST      SYS.XMLTYPE,
   XML_RESPONSE     SYS.XMLTYPE,
   REQUEST_PARAMS   VARCHAR2 (4000 BYTE),
   RESPONSE_PARAMS  VARCHAR2 (4000 BYTE),
   RESPONSE_COUNT   NUMBER,
   RETVAL 	    NUMBER,
   RETMSG 	    VARCHAR2 (4000 BYTE),
   EXECUTE_TIME     NUMBER
)


CREATE TABLE SDM$AML_CHECK_RES
(
   OBJID            VARCHAR2(12),
   TYPE_SPRAV       VARCHAR2(5),
   TEXT             VARCHAR2(200)
)


INSERT INTO GC.SDM_AML_SERVER 
VALUES('1','http://192.168.111.114:8081/amlws/amlws',1);

INSERT INTO GC.SDM_AML_TEMPLATE 
VALUES('GetInfoType','<soapenv:Envelope xmlns:req="http://support.diasoft.ru/type/request" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:type="http://support.diasoft.ru/type">
    <soapenv:Header>
        <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
            <wsse:UsernameToken wsu:Id="UsernameToken-33B33CA693EB81E1E4155914222266119">
                <wsse:Username>aml</wsse:Username>
                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile- 1.0#PasswordText">123</wsse:Password>
            </wsse:UsernameToken>
        </wsse:Security>
    </soapenv:Header>
    <soapenv:Body>
        <req:DsUnreliableBrowseListBaseAttrByParamReq>
            <ROWSCOUNT type="java.lang.Integer">300</ROWSCOUNT>
            <req:PAGE type="java.lang.Integer">0</req:PAGE>
            <req:ParticipantName>%NAME%</req:ParticipantName>
            <req:INN type="java.lang.String">%INN%</req:INN>
            <req:IdentityCardSeries>%SERIES%</req:IdentityCardSeries>
            <req:IdentityCardNumber>%NUMBER%</req:IdentityCardNumber>
            <req:BirthDate>%BIRTHDATE%</req:BirthDate>
            <req:UnreliableActiveStatus type="java.lang.Integer">0</req:UnreliableActiveStatus>
            <req:CoincidencePercent>100</req:CoincidencePercent>
            <req:FuzzySearchFlag type="java.lang.Boolean">true</req:FuzzySearchFlag>
            <req:TransliterationFlag type="java.lang.Boolean">true</req:TransliterationFlag>
            <req:SearchMode type="java.lang.Integer">2</req:SearchMode>
            <req:UnreliableCheckType type="java.lang.String">0</req:UnreliableCheckType>
        </req:DsUnreliableBrowseListBaseAttrByParamReq>
    </soapenv:Body>
</soapenv:Envelope>','1',NULL,NULL,'xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns2="http://support.diasoft.ru/type" xmlns:ns3="http://support.diasoft.ru/type/response" xmlns:ns4="http://support.diasoft.ru"',NULL,'1');
