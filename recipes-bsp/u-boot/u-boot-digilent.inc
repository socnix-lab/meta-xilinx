require recipes-bsp/u-boot/u-boot.inc
UBRANCH ?= "master"

LIC_FILES_CHKSUM = "file://README;beginline=1;endline=6;md5=157ab8408beab40cd8ce1dc69f702a6c"
UURI = "git://github.com/Digilent/u-boot-digilent.git;protocol=https"

# digilent-v2016.03 tag : "4dd0f06c46085cacc607dabbdf288bef6ad67115"
# u-boot-digilent-dev : ${AUTOREV}
SRCREV = '${@oe.utils.conditional( \
	"PREFERRED_PROVIDER_virtual/bootloader","u-boot-digilent-dev", \
	"${AUTOREV}", "4dd0f06c46085cacc607dabbdf288bef6ad67115", d)}'

UBOOT_EXTENSION = '${@oe.utils.conditional( \
	"PREFERRED_PROVIDER_virtual/bootloader","u-boot-digilent-dev", \
	"-digilent-dev", "digilent", d)}'

PV_PREFIX = '${@oe.utils.conditional( \
	"PREFERRED_PROVIDER_virtual/bootloader","u-boot-digilent-dev", \
	"${UBRANCH}", "v2016.03", d)}'

PV = "${PV_PREFIX}${UBOOT_EXTENSION}+git${SRCPV}"

SRC_URI = "${UURI};branch=${UBRANCH}"

COMPATIBLE_MACHINE = "zynq"

PROVIDES = "virtual/bootloader virtual/boot-bin"

UBOOT_BINARY = "u-boot-dtb.img"

# SPL binary boot.bin is in spl directory, no longer in the root
SPL_BINARY = "boot.bin"

SPL_IMAGE = "${SPL_BINARY}-${MACHINE}-${PV}-${PN}"

inherit zynq7-platform-paths

# Addition images for jtag boot and sdboot
EXTRA_UBOOT_IMGS ?= "${UBOOT_BINARY} u-boot-dtb.bin u-boot.bin spl/u-boot-spl.bin"

do_configure_prepend() {
	[ -e ${PLATFORM_INIT_STAGE_DIR}/ps7_init_gpl.h ] && \
		cp ${PLATFORM_INIT_STAGE_DIR}/ps7_init_gpl.h ${S}/board/xilinx/zynq/
	[ -e ${PLATFORM_INIT_STAGE_DIR}/ps7_init_gpl.c ] && \
		cp ${PLATFORM_INIT_STAGE_DIR}/ps7_init_gpl.c ${S}/board/xilinx/zynq/
}

do_install () {
	if [ -n "${SPL_BINARY}" ]; then
		install -d ${D}/boot
		install ${S}/spl/${SPL_BINARY} ${D}/boot/${SPL_IMAGE}
		ln -sf ${SPL_IMAGE} ${D}/boot/${SPL_BINARY}
		for p in ${EXTRA_UBOOT_IMGS}; do
			p_bn=$(basename ${S}/${p})
			install ${S}/${p} ${D}/boot/${p_bn}-${MACHINE}-${PV}-${PN}
			ln -sf ${p_bn}-${MACHINE}-${PV}-${PN} ${D}/boot/${p_bn}
		done
	fi
}

do_deploy () {
	if [ -n "${SPL_BINARY}" ]; then
		install ${S}/spl/${SPL_BINARY} ${DEPLOYDIR}/${SPL_IMAGE}
		rm -f ${DEPLOYDIR}/${SPL_BINARY} ${DEPLOYDIR}/${SPL_SYMLINK}
		ln -sf ${SPL_IMAGE} ${DEPLOYDIR}/${SPL_BINARY}
		ln -sf ${SPL_IMAGE} ${DEPLOYDIR}/${SPL_SYMLINK}
		for p in ${EXTRA_UBOOT_IMGS}; do
			p_bn=$(basename ${S}/${p})
			install ${S}/${p} ${DEPLOYDIR}/${p_bn}-${MACHINE}-${PV}-${PN}
			ln -sf ${p_bn}-${MACHINE}-${PV}-${PN} ${DEPLOYDIR}/${p_bn}
		done
	fi
}
