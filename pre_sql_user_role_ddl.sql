REM AUTHOR
REM   piyushjo@amazon.com
REM VERSION 1.0
REM SCRIPT
REM   pre_sql_user_role_ddl.sql
REM
REM DESCRIPTION
REM   This script generates another that contains the commands to
REM   create a user and role from source database
REM
REM PRE-REQUISITES
REM   1. execute permission on dbms_metadata package
REM
REM PARAMETERS
REM   1. SCHEMA to migrate
REM EXECUTION
REM   1. Connect into SQL*Plus as privileged user or user with access to
REM      data dictionary and dbms_metadata package.
REM   2. Execute script pre_sql_user_role_ddl.sql passing SCHEMA name.
REM
SET FEED OFF
SET ECHO OFF
SET HEAD OFF
SET ARRAYSIZE 1
SET SPACE 1
SET VERIFY OFF
SET PAGES 250
SET LINES 200
SET TERMOUT ON
CLEAR SCREEN
SET LONG 9999
SET SERVEROUTPUT ON SIZE 1000000

accept user_to_find char prompt   'NAME OF SCHEMA TO MIGRATE              [ADMIN]: ' default ADMIN
accept passwd char prompt   'PASSWORD OF SCHEMA TO MIGRATE              [asdfasdf]: ' default asdfasdf
PRO PRE REQ DDL FILE BEFORE IMPORT datapump_imp_exp_pre_&&user_to_find..sql

SPO datapump_imp_exp_pre_&&user_to_find..sql
select ddl3||';' from (select regexp_replace(ddl2,REGEXP_SUBSTR(ddl2,'(\S*)(\s)', 1,10),'&&passwd') as ddl3 from (select regexp_replace(ddl,REGEXP_SUBSTR(ddl,'(\S*)(\s)', 1,10)) as ddl2 from (select dbms_metadata.get_ddl('USER', '&&user_to_find') as ddl from dual)));
--select ddl||';' from (select dbms_metadata.get_ddl('USER', '&&user_to_find') as ddl from dual);
-- CREATE ROLES INCLUDING DEPEMDENT ROLE

declare
CURSOR C1 IS select distinct ROLES from (SELECT CONNECT_BY_ROOT GRANTED_ROLE as ROLES
      FROM dba_role_privs
       WHERE grantee = '&&user_to_find'
      CONNECT BY PRIOR grantee = GRANTED_ROLE) ;
sql_stmt  VARCHAR2(2000);
role_name     dba_roles.role%type;
begin
    OPEN C1;
    LOOP
            FETCH C1 INTO role_name;
            EXIT WHEN C1%NOTFOUND;
            if role_name not in ('RESOURCE','CONNECT') then
            for rec in (select dbms_metadata.get_ddl('ROLE', r.role) as ddl from   dba_roles r where  r.role = role_name
            union all
select dbms_metadata.get_granted_ddl('ROLE_GRANT', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = role_name
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('SYSTEM_GRANT', sp.grantee) AS ddl
from   dba_sys_privs sp
where  sp.grantee = role_name
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('OBJECT_GRANT', tp.grantee) AS ddl
from   dba_tab_privs tp
where  tp.grantee = role_name
and    rownum = 1) LOOP
dbms_output.put_line(rec.ddl||';');
    END LOOP;
    end if;
        END LOOP;

CLOSE C1;
END;
/
SPO OFF;
PRO ----------------------------------------------------------------------------\n
PRO
PRO PRE REQ DDL FILE BEFORE IMPORT : =>  datapump_imp_exp_pre_&&user_to_find..sql
undef user_to_find
undef passwd

