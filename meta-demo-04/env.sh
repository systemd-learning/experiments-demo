#!/bin/sh

CWD=`pwd`
PROGNAME="env.sh"
PACKAGE_CLASSES=${PACKAGE_CLASSES:-package_rpm}

usage()
{
    echo -e "
Usage: MACHINE=<machine> DISTRO=<distro> DL_DIR=<dl_dir> source $PROGNAME <build-dir>
Usage:                                                   source $PROGNAME <build-dir>
    <machine>    machine name
    <distro>     distro name
    <dl_dir>     download dir
    <build-dir>  build directory

Examples:

- To create a new Yocto build directory:
  $ MACHINE=soc-demo-01 DISTRO=distro-demo-01 source $PROGNAME build

- To use an existing Yocto build directory:
  $ source $PROGNAME build
"
}

clean()
{
   unset CWD SHORTOPTS LONGOPTS ARGS PROGNAME
   unset generated_config updated
   unset MACHINE DISTRO OEROOT
}

# get command line options
SHORTOPTS="h"
LONGOPTS="help"

ARGS=$(getopt --options $SHORTOPTS  \
  --longoptions $LONGOPTS --name $PROGNAME -- "$@" )
# Print the usage menu if invalid options are specified
if [ $? != 0 -o $# -lt 1 ]; then
   usage && clean
   return 1
fi

eval set -- "$ARGS"
while true;
do
    case $1 in
        -h|--help)
           usage
           clean
           return 0
           ;;
        --)
           shift
           break
           ;;
    esac
done

if [ "$(whoami)" = "root" ]; then
    echo "ERROR: do not use the BSP as root. Exiting..."
fi

if [ ! -e $1/conf/local.conf.sample ]; then
    build_dir_setup_enabled="true"
else
    build_dir_setup_enabled="false"
fi

if [ "$build_dir_setup_enabled" = "true" ] && [ -z "$MACHINE" ]; then
    usage
    echo -e "ERROR: You must set MACHINE when creating a new build directory."
    clean
    return 1
fi

if [ "$build_dir_setup_enabled" = "true" ] && [ -z "$DISTRO" ]; then
    usage
    echo -e "ERROR: You must set DISTRO when creating a new build directory."
    clean
    return 1
fi

OEROOT=$PWD/sources/poky
if [ -e $PWD/sources/oe-core ]; then
    OEROOT=$PWD/sources/oe-core
fi

TC_URL=https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/
TC_NAME=gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu
TC_SUFFIX=.tar.xz

if [ ! -e $DL_DIR/$TC_NAME ]; then
    if [ ! -f $DL_DIR/$TC_NAME ]; then
        wget $TC_URL/${TC_NAME}${TC_SUFFIX} -O- > $DL_DIR/${TC_NAME}${TC_SUFFIX}
    else
        mkdir -p $DL_DIR/$TC_NAME
        tar -xf $DL_DIR/${TC_NAME}${TC_SUFFIX} --strip-components=1  -C $DL_DIR/$TC_NAME
    fi
fi

. $OEROOT/oe-init-build-env $CWD/$1 > /dev/null

# if conf/local.conf not generated, no need to go further
if [ ! -e conf/local.conf ]; then
    clean && return 1
fi

# Clean up PATH, because if it includes tokens to current directories somehow,
# wrong binaries can be used instead of the expected ones during task execution
export PATH="`echo $PATH | sed 's/\(:.\|:\)*:/:/g;s/^.\?://;s/:.\?$//'`"

generated_config=
if [ "$build_dir_setup_enabled" = "true" ]; then
    cp $CWD/sources/demo/meta-demo-04/conf/bblayers.conf  conf/

    mv conf/local.conf conf/local.conf.sample

    # Generate the local.conf based on the Yocto defaults
    grep -v '^#\|^$' conf/local.conf.sample > conf/local.conf
    # Change settings according environment
    sed -e "s,MACHINE ??=.*,MACHINE ??= '$MACHINE',g" \
        -e "s,DISTRO ?=.*,DISTRO ?= '$DISTRO',g" \
        -e "s,PACKAGE_CLASSES ?=.*,PACKAGE_CLASSES ?= '$PACKAGE_CLASSES',g" \
        -i conf/local.conf

    cat >> conf/local.conf <<EOF
DL_DIR ?= "${DL_DIR}"
TCMODE = "external-arm"
EXTERNAL_TOOLCHAIN="${DL_DIR}/${TC_NAME}"

PREFERRED_PROVIDER_virtual/kernel = "linux-kernel"

DISTRO_FEATURES:remove = " sysvinit 3g bluetooth irda nfc zeroconf x11 xorg wayland"
DISTRO_FEATURES:remove = "ptest"
DISTRO_FEATURES:append = " systemd"
DISTRO_FEATURES_BACKFILL_CONSIDERED += "sysvinit"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

EOF

    generated_config=1
fi

if [ -n "$generated_config" ]; then
    cat <<EOF
Your build environment has been configured with:

    MACHINE=$MACHINE
    DISTRO=$DISTRO
    DL_DIR=$DL_DIR
EOF
else
    echo "Your configuration files at $1 have not been touched."
fi

clean
