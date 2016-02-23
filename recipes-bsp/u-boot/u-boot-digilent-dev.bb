# To enable this recipe, set the following in your machine or local.conf
#   PREFERRED_PROVIDER_virtual/bootloader ?= "u-boot-digilent-dev"
#   PREFERRED_PROVIDER_u-boot ?= "u-boot-digilent-dev"

UBRANCH ?= "master"

include u-boot-xlnx.inc
include u-boot-extra.inc

LIC_FILES_CHKSUM = "file://README;beginline=1;endline=6;md5=157ab8408beab40cd8ce1dc69f702a6c"
UURI = "git://github.com/Digilent/u-boot-digilent.git;protocol=https"

SRCREV = "${AUTOREV}"

XILINX_EXTENSION = "-digilent"

PV = "${UBRANCH}${XILINX_EXTENSION}+git${SRCPV}"

SRC_URI = "${UURI};branch=${UBRANCH}"

COMPATIBLE_MACHINE = "zynq"

PROVIDES = "virtual/bootloader virtual/boot-bin"

# SPL binary boot.bin is in spl directory, no longer in the root
SPL_BINARY = "boot.bin"
UBOOT_MAKE_TARGET ?= "boot.bin"

inherit zynq7-platform-paths

# Addition images for jtag boot and sdboot
EXTRA_UBOOT_IMGS ?= "u-boot-dtb.img u-boot-dtb.bin u-boot.bin spl/u-boot-spl.bin"

do_configure_prepend() {
	[ -e ${PLATFORM_INIT_STAGE_DIR}/ps7_init_gpl.h ] && \
		cp ${PLATFORM_INIT_STAGE_DIR}/ps7_init_gpl.h ${S}/board/xilinx/zynq/
	[ -e ${PLATFORM_INIT_STAGE_DIR}/ps7_init_gpl.c ] && \
		cp ${PLATFORM_INIT_STAGE_DIR}/ps7_init_gpl.c ${S}/board/xilinx/zynq/
}

do_install () {
	if [ "x${SPL_BINARY}" != "x" ]; then
		install -d ${D}/boot
		install ${S}/spl/${SPL_BINARY} ${D}/boot/${SPL_IMAGE}
		ln -sf ${SPL_IMAGE} ${D}/boot/${SPL_BINARY}
		for p in ${EXTRA_UBOOT_IMGS}; do
			p_bn=$(basename ${S}/${p})
			install ${S}/${p} ${D}/boot/${p_bn}-${PV}
			ln -sf ${p_bn}-${PV} ${D}/boot/${p_bn}
		done
	fi
}

do_deploy () {
	if [ "x${SPL_BINARY}" != "x" ]; then
		install ${S}/spl/${SPL_BINARY} ${DEPLOYDIR}/${SPL_IMAGE}
		rm -f ${DEPLOYDIR}/${SPL_BINARY} ${DEPLOYDIR}/${SPL_SYMLINK}
		ln -sf ${SPL_IMAGE} ${DEPLOYDIR}/${SPL_BINARY}
		ln -sf ${SPL_IMAGE} ${DEPLOYDIR}/${SPL_SYMLINK}
		for p in ${EXTRA_UBOOT_IMGS}; do
			p_bn=$(basename ${S}/${p})
			install ${S}/${p} ${DEPLOYDIR}/${p_bn}-${PV}
			ln -sf ${p_bn}-${PV} ${DEPLOYDIR}/${p_bn}
		done
	fi
}
