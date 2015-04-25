JAIL_ROOT_DIR="${jailsysdir}/${jname}"
SKEL_DIR="${JAIL_ROOT_DIR}/skel"
PRODUCT="logstash"

# keep this settins for imghelper
formfile="${JAIL_ROOT_DIR}/bin/forms.sqlite"

install_img()
{
	[ ! -d "${path}/usr/local/etc/nginx/vhosts" ] && mkdir -p "${path}/usr/local/etc/nginx/vhosts"
	sed s:MY.HOSTNAME:${fqdn}:g ${SKEL_DIR}/etc/elasticsearch-vhosts.conf > ${path}/usr/local/etc/nginx/vhosts/elasticsearch.conf
	sed s:MY.HOSTNAME:${fqdn}:g ${SKEL_DIR}/etc/logstash-vhost.conf > ${path}/usr/local/etc/nginx/vhosts/logstash.conf
	sed s:MY.HOSTNAME:${fqdn}:g ${SKEL_DIR}/etc/elasticsearch.yml > ${path}/usr/local/etc/elasticsearch/elasticsearch.yml
	sed s:MY.HOSTNAME:${fqdn}:g ${SKEL_DIR}/etc/logstash.conf > ${path}/usr/local/etc/logstash/logstash.conf

	# cleanup
	# remove CBSD pkg repos
	[ -d "${path}/usr/local/etc/pkg" ] && rm -rf "${path}/usr/local/etc/pkg"
}

img_message()
{
	echo
	${ECHO} "${BOLD}=======================================${NORMAL}"
	${ECHO} "${MAGENTA}${PRODUCT} installed. After jail start, default installation${NORMAL}"
	${ECHO} "${MAGENTA}will be available via: ${GREEN}http://${fqdn}${NORMAL}"
	echo
}
