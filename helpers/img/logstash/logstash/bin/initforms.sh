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
INSERT INTO forms ( group_id,order_id,param,desc,def,cur,new,mandatory,attr,type ) VALUES ( 1,1,"server_name","server_name for vhost",'example.my.domain','','',1, "maxlen=60", "inputbox" );
INSERT INTO forms ( group_id,order_id,param,desc,def,cur,new,mandatory,attr,type ) VALUES ( 1,2,"http_index","index file",'index.php','','',1, "maxlen=30", "inputbox" );
INSERT INTO forms ( group_id,order_id,param,desc,def,cur,new,mandatory,attr,type ) VALUES ( 1,3,"http_root","Document Root path",'/usr/home/web/site1/public_html','','',1, "maxlen=128", "inputbox" );
COMMIT;
EOF

# Put version
/usr/local/bin/cbsd ${miscdir}/updatesql ${MYPATH}/forms.sqlite /usr/local/cbsd/share/forms_version.schema

/usr/local/bin/sqlite3 ${MYPATH}/forms.sqlite << EOF
BEGIN TRANSACTION;
INSERT INTO system ( version ) VALUES ( "201502" );
COMMIT;
EOF
