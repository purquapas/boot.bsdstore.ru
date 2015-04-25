# This is the part of CBSD project
# Simple helper for NGINX service to install vhost
#
JAIL_ROOT_DIR="${jailsysdir}/${jname}"
SKEL_DIR="${JAIL_ROOT_DIR}/skel"
PRODUCT="nginx"

# keep this settins for imghelper
: ${formfile="${JAIL_ROOT_DIR}/bin/forms.sqlite"}

install_img_orig()
{
	chroot ${path} /bin/sh << EOF
/root/skel/mysql ${mypw} ${hosts} ${network}
/bin/rm -rf /root/skel
EOF

	# cleanup
	# remove CBSD pkg repos
	[ -d "${path}/usr/local/etc/pkg" ] && /bin/rm -rf "${path}/usr/local/etc/pkg"
}

regen_nginx_conf()
{
	local tplconf="${helper_workdir}/nginx.conf"
	local newconf="${path}/usr/local/etc/nginx/nginx.conf"
	local tpl_php_core="${helper_workdir}/php-core.conf"
	local new_php_core="${path}/usr/local/etc/nginx/php-core.conf"

	[ ! -f "${tplconf}" ] && err 1 "${MAGENTA}No such template in: ${GREEN}${tplconf}${NORMAL}"
	[ ! -f "${tpl_php_core}" ] && err 1 "${MAGENTA}No such template in: ${GREEN}${tpl_php_core}${NORMAL}"

	# %%WORKER_PROCESSES%% determine automatically or get from input form
	local worker_processess=1

	# %%USER%% %%GROUP%%
	local user=www
	local group=www

	# %%HTTP_PORT%%
	local http_port=80

	# %%ERROR_LOG%%
	local error_log="/var/log/httpd/nginx.err"

	[ ! -d "${path}/usr/local/etc/nginx" ] && mkdir -p ${path}/usr/local/etc/nginx

	/usr/bin/sed -Ees:%%WORKER_PROCESSES%%:"${worker_processess}":g \
	-es:%%USER%%:"${user}":g \
	-es:%%GROUP%%:"${group}":g \
	-es:%%HTTP_PORT%%:"${http_port}":g \
	-es:%%ERROR_LOG%%:"${error_log}":g \
	${tplconf} > ${newconf}
	
	/bin/cp ${tpl_php_core} ${new_php_core}
}

regen_nginx_vhosts()
{
	local tplconf="${helper_workdir}/vhosts-minimal.conf"
	local newconf="${path}/usr/local/etc/nginx/vhosts/vhost.conf"

	[ ! -f "${tplconf}" ] && err 1 "${MAGENTA}No such template in: ${GREEN}${tplconf}${NORMAL}"

	# %%HTTP_PORT%%
	local http_port=80

	# %%SERVER_NAME%%
	[ -z "${server_name}" ] && err 1 "${MAGENTA}No server_name variable${NORMAL}"

	# %%ERROR_LOG%%
#	[ -z "${error_log}" ] && local error_log="/var/log/httpd/${server_name}.err"
	[ -z "${error_log}" ] && local error_log="/var/log/httpd/vhost.err"

	# %%ERROR_LEVEL%%
	[ -z "${error_level}" ] && local error_level="error"

	# %%ACCESS_LOG%%
#	[ -z "${access_log}" ] && local access_log="/var/log/httpd/${server_name}.acc"
	[ -z "${access_log}" ] && local access_log="/var/log/httpd/vhost.acc"

	# %%HTTP_ROOT%%
	[ -z "${http_root}" ] && local http_root="/usr/home/web/${server_name}/public_html"

	# %%HTTP_INDEX%%
	[ -z "${http_index}" ] && local http_index="index.html index.htm"

	[ ! -d "${path}/var/log/httpd" ] && mkdir -p ${path}/var/log/httpd
	[ ! -d "${path}/${http_root}" ] && mkdir -p ${path}/${http_root}
	[ ! -d "${path}/usr/local/etc/nginx/vhosts" ] && mkdir -p ${path}/usr/local/etc/nginx/vhosts

	/usr/bin/sed -Ees:%%HTTP_PORT%%:"${http_port}":g \
	-es:%%SERVER_NAME%%:"${server_name}":g \
	-es:%%ERROR_LOG%%:"${error_log}":g \
	-es:%%ERROR_LEVEL%%:"${error_level}":g \
	-es:%%ACCESS_LOG%%:"${access_log}":g \
	-es:%%HTTP_ROOT%%:"${http_root}":g \
	-es:%%HTTP_INDEX%%:"${http_index}":g \
	${tplconf} > ${newconf}
}

# store old config to temporary place
make_backup()
{
	local nginxconf="${path}/usr/local/etc/nginx.conf"
	local vhostconf="${path}/usr/local/etc/vhosts/vhost.conf"
	local nginxconfbkp="${jailsysdir}/${jname}/nginx.conf.$$"
	local vhostconfbkp="${jailsysdir}/${jname}/vhost.conf.$$"

	trap "/bin/rm -f ${nginxconfbkp} ${vhostconfbkp}" HUP INT ABRT BUS TERM EXIT

	[ -f "${nginxconf}" ] && /bin/cp ${nginxconf} ${nginxconfbkp}
	[ -f "${vhostconf}" ] && /bin/cp ${vhostconf} ${vhostconfbkp}
}

# restore old config from backup
restore_backup()
{
	local nginxconf="${path}/usr/local/etc/nginx.conf"
	local vhostconf="${path}/usr/local/etc/vhosts/vhost.conf"
	local nginxconfbkp="${jailsysdir}/${jname}/nginx.conf.$$"
	local vhostconfbkp="${jailsysdir}/${jname}/vhost.conf.$$"

	[ -f "${nginxconfbkp}" ] && /bin/mv ${nginxconfbkp} ${nginxconf}
	[ -f "${vhostconfbkp}" ] && /bin/mv ${vhostconfbkp} ${vhostconf}
	trap "" HUP INT ABRT BUS TERM EXIT
}

# exec nginx configtest and return code
nginx_conf_test()
{
	local _ret

	local mode

	service jname=${jname} nginx oneconfigtest

	_ret=$?
	return ${_ret}
}

update_current_val()
{
	local i _T

	for i in ${param}; do
		eval _T=\${${i}}
		[ -z "${_T}" ] && continue
		${miscdir}/sqlcli ${formfile} UPDATE forms SET cur=\"${_T}\" WHERE param=\"${i}\"
	done

	return 0
}


# rename/move logs/docroot data
migrate_data()
{
	local oldroot newroot
	# docroot
	oldroot=$( cbsdsql ${formfile} SELECT cur FROM forms WHERE param=\"http_root\" )
	newroot=$( cbsdsql ${formfile} SELECT new FROM forms WHERE param=\"http_root\" )

	if [ "$oldroot" != "$newroot" ]; then
		[ -d "${path}${oldroot}" ] && /bin/mv ${path}${oldroot} ${path}${newroot}
	fi
	[ ! -d "${path}${newroot}" ] && /bin/mkdir -p ${path}${newroot}
}

install_img()
{
	local _res _ret
	make_backup

	regen_nginx_conf
	regen_nginx_vhosts

	nginx_conf_test
	_ret=$?

	case ${_ret} in
		0)
			migrate_data
			update_current_val
			[ "${active_jail}" = "1" ] && service jname=${jname} nginx onereload
			;;
		*)
			restore_backup
			err 1 "${MAGENTA}Bad config. Rollback${NORMAL}"
			echo "${_res}"
			;;
	esac
}

# For imghelper
img_message()
{
	echo
	${ECHO} "${BOLD}=======================================${NORMAL}"
	${ECHO} "${MAGENTA}${PRODUCT} configured.${NORMAL}"
	echo
}
