#!/bin/sh
MYDIR="$( /usr/bin/dirname $0 )"
MYPATH="$( /bin/realpath ${MYDIR} )"

. /etc/rc.conf
workdir="${cbsd_workdir}"
. ${workdir}/cbsd.conf

[ -f "${MYPATH}/forms.sqlite" ] && /bin/rm -f "${MYPATH}/forms.sqlite"

/usr/local/bin/cbsd ${miscdir}/updatesql ${MYPATH}/forms.sqlite /usr/local/cbsd/share/forms.schema

/usr/local/bin/sqlite3 ${MYPATH}/forms.sqlite << EOF
BEGIN TRANSACTION;
INSERT INTO forms ( group_id,order_id,param,desc,def,cur,new,mandatory,attr,type ) VALUES ( 1,1,"port","default is 6379. 0 - not listen on a TCP socket",'6379','','',1, "maxlen=60", "inputbox" );
INSERT INTO forms ( group_id,order_id,param,desc,def,cur,new,mandatory,attr,type ) VALUES ( 1,2,"requirepass","Require clients to issue AUTH <PASSWORD>",'','','',1, "maxlen=30", "inputbox" );
INSERT INTO forms ( group_id,order_id,param,desc,def,cur,new,mandatory,attr,type ) VALUES ( 1,3,"maxmemory","Don't use more memory than the specified amount of byte",'1g','','',1, "maxlen=128", "inputbox" );
INSERT INTO forms ( group_id,order_id,param,desc,def,cur,new,mandatory,attr,type ) VALUES ( 1,3,"maxmemory-policy","maxmemory policy",'volatile-lru','','',1, "maxlen=128", "inputbox" );
COMMIT;
EOF

# Put version
/usr/local/bin/cbsd ${miscdir}/updatesql ${MYPATH}/forms.sqlite /usr/local/cbsd/share/forms_version.schema

/usr/local/bin/sqlite3 ${MYPATH}/forms.sqlite << EOF
BEGIN TRANSACTION;
INSERT INTO system ( version ) VALUES ( "201502" );
COMMIT;
EOF
