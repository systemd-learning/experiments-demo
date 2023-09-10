LICENSE = "GPLv2"
DESCRIPTION = "Linux 5.10 kernel for experiments"
KERNEL_CONFIG_COMMAND ?= "oe_runmake_call -C ${S} CC="${KERNEL_CC}" O=${B} olddefconfig"

inherit kernel-yocto
require recipes-kernel/linux/linux-yocto.inc
KERNEL_MODULE_PACKAGE_SUFFIX = "-${@ (d.getVar('KERNEL_VERSION') or '').lower().replace('_', '-').replace('@', '+') }"

# Override kernel license checksum
FILES:${KERNEL_PACKAGE_NAME}-base += "${nonarch_base_libdir}/modules/${KERNEL_VERSION}/modules.builtin.modinfo"
inherit externalsrc

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"
COMPATIBLE_MACHINE = "qemuarm64"
KMETA = "kernel-meta"
KCONF_BSP_AUDIT_LEVEL = "1"
LINUX_SRC_DIR = "${THISDIR}/../../"

LINUX_VERSION ?= "5.10.59"
PV = "${LINUX_VERSION}"
PR = "r0"
# The previous line should not be necessary when those 2 are added
# but it doesn't work..

EXTERNALSRC:pn-linux-kernel = "${LINUX_SRC_DIR}/sources/linux"
EXTERNALSRC_BUILD:pn-linux-kernel = "${B}"
KBUILD_OUTPUT = "${B}"
OE_TERMINAL_EXPORTS += "KBUILD_OUTPUT"
S = "${LINUX_SRC_DIR}/sources/linux"

do_shared_workdir:append () {
    rm -rf ${STAGING_KERNEL_DIR}
    ln -sf ${S} ${STAGING_KERNEL_DIR}
}

do_deploy() {
    kernel_do_deploy
}

addtask do_shared_workdir after do_compile before do_install

DEPENDS += "${@bb.utils.contains('ARCH', 'x86', 'elfutils-native', '', d)}"
DEPENDS += "openssl-native util-linux-native"
DEPENDS += "gmp-native libmpc-native"

