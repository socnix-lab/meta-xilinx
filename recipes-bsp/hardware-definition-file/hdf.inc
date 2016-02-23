SECTION = "bsp"
DEPENDS += "unzip"
COMPATIBLE_MACHINE ?= "zybo-zynq7"


S ?= "${WORKDIR}/${MACHINE}"

PROVIDES = "virtual/hdf virtual/bitstream virtual/zynq7-platform-init"

BITSTREAM ?= ".bit"

FILESEXTRAPATHS_prepend := "${THISDIR}/bsps:"

PLATFORM_INIT ?= "ps7_init_gpl.c \
		  ps7_init_gpl.h"

FILES_${PN} += " \
		${PLATFORM_INIT_DIR}/ps7_init_gpl.c \
		${PLATFORM_INIT_DIR}/ps7_init_gpl.h \
		/boot/download.bit \
		"

INHIBIT_DEFAULT_DEPS = "1"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit zynq7-platform-paths

do_compile() {
	unzip -o ${S}/${HDF}
}

do_install() {
	boot=${D}/boot
	install -d ${boot}
	bitstream=$(find ${S} -maxdepth 1 -type f -name "*${BITSTREAM}")
	install -m 0644 ${bitstream} ${boot}/download.bit

	install -d ${PLATFORM_INIT_STAGE_DIR}
	for f in ${PLATFORM_INIT}; do
		ps7_init=$(find ${S} -maxdepth 1 -type f -name "$f")
		install ${ps7_init} ${PLATFORM_INIT_STAGE_DIR}
	done
}

do_deploy () {
	if [ -e ${D}/boot/download.bit ]; then
		install -d ${DEPLOY_DIR_IMAGE}
		bit_basename="download.bit-${PV}-${PR}-${MACHINE}.bit"
		install -m 0644 ${D}/boot/download.bit ${DEPLOY_DIR_IMAGE}/${bit_basename}
		ln -sf ${bit_basename} ${DEPLOY_DIR_IMAGE}/download.bit
	fi
}
addtask deploy before do_build after do_install
