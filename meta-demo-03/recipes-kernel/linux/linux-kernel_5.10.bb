LICENSE = "GPLv2"
DESCRIPTION = "Linux 5.10 kernel for experiments"
KERNEL_CONFIG_COMMAND ?= "oe_runmake_call -C ${S} CC="${KERNEL_CC}" O=${B} olddefconfig"

inherit kernel-yocto
require recipes-kernel/linux/linux-yocto.inc
KERNEL_MODULE_PACKAGE_SUFFIX = "-${@ (d.getVar('KERNEL_VERSION') or '').lower().replace('_', '-').replace('@', '+') }"

# Override kernel license checksum
FILES:${KERNEL_PACKAGE_NAME}-base += "${nonarch_base_libdir}/modules/${KERNEL_VERSION}/modules.builtin.modinfo"
inherit externalsrc

SRC_URI += "file://defconfig"

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"
COMPATIBLE_MACHINE = "qemuarm64"
KMETA = "kernel-meta"
KCONF_BSP_AUDIT_LEVEL = "1"
LINUX_SRC_DIR = "${THISDIR}/../../../../"

LINUX_VERSION ?= "5.10.59"
PV = "${LINUX_VERSION}"
PR = "r0"

KCONFIG_MODE="--alldefconfig"
SRCREV_machine:qemuarm64 ?= "${AUTOREV}"
KBUILD_DEFCONFIG:qemuarm64 ?= "${KERNEL_DEFCONFIG}"

EXTERNALSRC:pn-linux-kernel = "${LINUX_SRC_DIR}/linux"
EXTERNALSRC_BUILD:pn-linux-kernel = "${B}"
KBUILD_OUTPUT = "${B}"
OE_TERMINAL_EXPORTS += "KBUILD_OUTPUT"
S = "${LINUX_SRC_DIR}/linux"

KERNEL_DANGLING_FEATURES_WARN_ONLY = "1"
do_shared_workdir:append () {
    rm -rf ${STAGING_KERNEL_DIR}
    ln -sf ${S} ${STAGING_KERNEL_DIR}
}

do_deploy() {
    kernel_do_deploy
}

# We store patches in ${S}/rt-patches and yocto applies patches only if they
# are listed in SRC_URI. Thus, we want to apply patches only if we want RT
python do_apply_patches() {
    import subprocess
    import os

    s_dir = d.getVar('S')
    if os.path.exists(s_dir+"/localversion-rt"):
        print("Pre-applied RT patches detected. Not applying them again.")
    else:
        try:
            subprocess.check_output("git am rt-patches/*.patch", cwd=s_dir, shell=True)
            subprocess.check_output("git am android-patches/*.patch", cwd=s_dir, shell=True)
        except subprocess.CalledProcessError as e:
            print(e.output)
            bb.fatal('apply patches failed!')
}

do_apply_patches[depends] = " kern-tools-native:do_populate_sysroot  patch-native:do_populate_sysroot "

addtask do_shared_workdir after do_compile before do_install
addtask do_apply_patches after do_unpack before do_kernel_configme

DEPENDS += "${@bb.utils.contains('ARCH', 'x86', 'elfutils-native', '', d)}"
DEPENDS += "openssl-native util-linux-native"
DEPENDS += "gmp-native libmpc-native"

