FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
			file://0008-show-status-full-info.patch \
                        file://rc.local \
                        file://var-volatile.mount \
			"

PACKAGECONFIG[iptables-generator] = ""
FILES:${PN} += "${sysconfdir}/rc.local"
FILES:${PN} += "${sysconfdir}/systemd/system/var-volatile.mount"
PACKAGECONFIG:remove = "timesyncd"

inherit externalsrc

EXTERNALSRC = "${EXTERNALSRC_SYSTEMD}"

do_install() {
	meson_do_install
	install -d ${D}/${base_sbindir}
	if ${@bb.utils.contains('PACKAGECONFIG', 'serial-getty-generator', 'false', 'true', d)}; then
		# Provided by a separate recipe
		rm ${D}${systemd_system_unitdir}/serial-getty* -f
	fi

	# Provide support for initramfs
	[ ! -e ${D}/init ] && ln -s ${rootlibexecdir}/systemd/systemd ${D}/init
	[ ! -e ${D}/${base_sbindir}/udevd ] && ln -s ${rootlibexecdir}/systemd/systemd-udevd ${D}/${base_sbindir}/udevd

	install -d ${D}${sysconfdir}/udev/rules.d/
	install -d ${D}${sysconfdir}/tmpfiles.d
	for rule in $(find ${WORKDIR} -maxdepth 1 -type f -name "*.rules"); do
		install -m 0644 $rule ${D}${sysconfdir}/udev/rules.d/
	done

	install -m 0644 ${WORKDIR}/00-create-volatile.conf ${D}${sysconfdir}/tmpfiles.d/

	if ${@bb.utils.contains('DISTRO_FEATURES','sysvinit','true','false',d)}; then
		install -d ${D}${sysconfdir}/init.d
		install -m 0755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/systemd-udevd
		sed -i s%@UDEVD@%${rootlibexecdir}/systemd/systemd-udevd% ${D}${sysconfdir}/init.d/systemd-udevd
		install -Dm 0755 ${S}/src/systemctl/systemd-sysv-install.SKELETON ${D}${systemd_system_unitdir}d-sysv-install
	fi

	chown root:systemd-journal ${D}/${localstatedir}/log/journal

	# Delete journal README, as log can be symlinked inside volatile.
	rm -f ${D}/${localstatedir}/log/README

	# journal-remote creates this at start
	rm -rf ${D}/${localstatedir}/log/journal/remote

	install -d ${D}${systemd_system_unitdir}/graphical.target.wants
	install -d ${D}${systemd_system_unitdir}/multi-user.target.wants
	install -d ${D}${systemd_system_unitdir}/poweroff.target.wants
	install -d ${D}${systemd_system_unitdir}/reboot.target.wants
	install -d ${D}${systemd_system_unitdir}/rescue.target.wants

	# Create symlinks for systemd-update-utmp-runlevel.service
	if ${@bb.utils.contains('PACKAGECONFIG', 'utmp', 'true', 'false', d)}; then
		ln -sf ../systemd-update-utmp-runlevel.service ${D}${systemd_system_unitdir}/graphical.target.wants/systemd-update-utmp-runlevel.service
		ln -sf ../systemd-update-utmp-runlevel.service ${D}${systemd_system_unitdir}/multi-user.target.wants/systemd-update-utmp-runlevel.service
		ln -sf ../systemd-update-utmp-runlevel.service ${D}${systemd_system_unitdir}/poweroff.target.wants/systemd-update-utmp-runlevel.service
		ln -sf ../systemd-update-utmp-runlevel.service ${D}${systemd_system_unitdir}/reboot.target.wants/systemd-update-utmp-runlevel.service
		ln -sf ../systemd-update-utmp-runlevel.service ${D}${systemd_system_unitdir}/rescue.target.wants/systemd-update-utmp-runlevel.service
	fi

	# this file is needed to exist if networkd is disabled but timesyncd is still in use since timesyncd checks it
	# for existence else it fails
	if [ -s ${D}${exec_prefix}/lib/tmpfiles.d/systemd.conf ]; then
		${@bb.utils.contains('PACKAGECONFIG', 'networkd', ':', 'sed -i -e "$ad /run/systemd/netif/links 0755 root root -" ${D}${exec_prefix}/lib/tmpfiles.d/systemd.conf', d)}
	fi
	if ! ${@bb.utils.contains('PACKAGECONFIG', 'resolved', 'true', 'false', d)}; then
		echo 'L! ${sysconfdir}/resolv.conf - - - - ../run/systemd/resolve/resolv.conf' >>${D}${exec_prefix}/lib/tmpfiles.d/etc.conf
		echo 'd /run/systemd/resolve 0755 root root -' >>${D}${exec_prefix}/lib/tmpfiles.d/systemd.conf
		echo 'f /run/systemd/resolve/resolv.conf 0644 root root' >>${D}${exec_prefix}/lib/tmpfiles.d/systemd.conf
		ln -s ../run/systemd/resolve/resolv.conf ${D}${sysconfdir}/resolv-conf.systemd
	else
		sed -i -e "s%^L! /etc/resolv.conf.*$%L! /etc/resolv.conf - - - - ../run/systemd/resolve/resolv.conf%g" ${D}${exec_prefix}/lib/tmpfiles.d/etc.conf
		ln -s ../run/systemd/resolve/resolv.conf ${D}${sysconfdir}/resolv-conf.systemd
	fi
	if ${@bb.utils.contains('DISTRO_FEATURES', 'x11', 'false', 'true', d)}; then
		rm ${D}${exec_prefix}/lib/tmpfiles.d/x11.conf
		rm -r ${D}${sysconfdir}/X11
	fi

	# If polkit is setup fixup permissions and ownership
	if ${@bb.utils.contains('PACKAGECONFIG', 'polkit', 'true', 'false', d)}; then
		if [ -d ${D}${datadir}/polkit-1/rules.d ]; then
			chmod 700 ${D}${datadir}/polkit-1/rules.d
			chown polkitd:root ${D}${datadir}/polkit-1/rules.d
		fi
	fi

	# If polkit is not available and a fallback was requested, install a drop-in that allows networkd to
	# request hostname changes via DBUS without elevating its privileges
	if ${@bb.utils.contains('PACKAGECONFIG', 'polkit_hostnamed_fallback', 'true', 'false', d)}; then
		install -d ${D}${systemd_system_unitdir}/systemd-hostnamed.service.d/
		install -m 0644 ${WORKDIR}/00-hostnamed-network-user.conf ${D}${systemd_system_unitdir}/systemd-hostnamed.service.d/
		install -d ${D}${datadir}/dbus-1/system.d/
		install -m 0644 ${WORKDIR}/org.freedesktop.hostname1_no_polkit.conf ${D}${datadir}/dbus-1/system.d/
	fi

	# create link for existing udev rules
	ln -s ${base_bindir}/udevadm ${D}${base_sbindir}/udevadm

	# duplicate udevadm for postinst script
	install -d ${D}${libexecdir}
	ln ${D}${base_bindir}/udevadm ${D}${libexecdir}/${MLPREFIX}udevadm

	# install default policy for presets
	# https://www.freedesktop.org/wiki/Software/systemd/Preset/#howto
	install -Dm 0644 ${WORKDIR}/99-default.preset ${D}${systemd_system_unitdir}-preset/99-default.preset

	# add a profile fragment to disable systemd pager with busybox less
	install -Dm 0644 ${WORKDIR}/systemd-pager.sh ${D}${sysconfdir}/profile.d/systemd-pager.sh
}

do_install:append () {
	if ${@bb.utils.contains('PACKAGECONFIG', 'iptables-generator', 'false', 'true', d)}; then
		# Provided by a separate recipe
		rm ${D}${systemd_system_unitdir}/iptables* -f
	fi

        install -m 755 ${WORKDIR}/rc.local  ${D}${sysconfdir}/rc.local
        install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
        cp -r ${WORKDIR}/var-volatile.mount ${D}${sysconfdir}/systemd/system/var-volatile.mount

        printf "\n[Install]\n" >> ${D}${systemd_system_unitdir}/rc-local.service
        printf "WantedBy=multi-user.target\n" >> ${D}${systemd_system_unitdir}/rc-local.service
        ln -s ${systemd_system_unitdir}/rc-local.service ${D}${sysconfdir}/systemd/system/multi-user.target.wants/rc-local.service
}

RDEPENDS:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'iptables-generator', '', 'systemd-iptables', d)}"
