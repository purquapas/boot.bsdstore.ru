#!/bin/sh
MYDIR="$( dirname $0 )"
MYPATH="$( realpath ${MYDIR} )"

. /etc/rc.conf
workdir="${cbsd_workdir}"
. ${workdir}/cbsd.conf

[ -f "${MYPATH}/forms.sqlite" ] && rm -f "${MYPATH}/forms.sqlite"

/usr/local/bin/cbsd ${miscdir}/updatesql ${MYPATH}/forms.sqlite /usr/local/cbsd/share/forms.schema

/usr/local/bin/sqlite3 ${MYPATH}/forms.sqlite << EOF
BEGIN TRANSACTION;
INSERT INTO forms ( group_id,order_id,param,desc,def,cur,new,mandatory,attr,type ) VALUES ( 1,1,"fqdn","Please enter vhost FQDN",'example.my.domain','','',1, "maxlen=60", "inputbox" );
COMMIT;
EOF

# Put version
/usr/local/bin/cbsd ${miscdir}/updatesql ${MYPATH}/forms.sqlite /usr/local/cbsd/share/forms_version.schema

/usr/local/bin/sqlite3 ${MYPATH}/forms.sqlite << EOF
BEGIN TRANSACTION;
INSERT INTO system ( version ) VALUES ( "201502" );
COMMIT;
EOF
