SUMMARY = "Serial terminal support for systemd"
HOMEPAGE = "https://www.freedesktop.org/wiki/Software/systemd/"
LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

PR = "r5"

#SERIAL_CONSOLES ?= "115200;ttyS0"
SERIAL_TERM ?= "linux"

SRC_URI = "file://iptables@.service"

S = "${WORKDIR}"

# As this package is tied to systemd, only build it when we're also building systemd.
inherit features_check
REQUIRED_DISTRO_FEATURES = "systemd"

do_install() {
	install -d ${D}${systemd_system_unitdir}/
	install -d ${D}${sysconfdir}/systemd/system/getty.target.wants/
	install -m 0644 ${WORKDIR}/iptables@.service ${D}${systemd_system_unitdir}/
}

# This is a machine specific file
FILES:${PN} = "${systemd_system_unitdir}/*.service ${sysconfdir}"
PACKAGE_ARCH = "${MACHINE_ARCH}"

ALLOW_EMPTY:${PN} = "1"
