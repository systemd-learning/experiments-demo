SUMMARY = "custom modules"
LICENSE = "CLOSED"

inherit module

PR = "r0"
PV = "0.1"

KERNEL_DIR = "${THISDIR}/../../../../linux"


SRC_URI = "file://demo.c \
	   file://Makefile \
	   "

S = "${WORKDIR}"

