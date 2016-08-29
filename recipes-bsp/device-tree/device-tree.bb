SUMMARY = "Device Trees for BSPs"
DESCRIPTION = "Device Tree generation and packaging for BSP Device Trees."
SECTION = "bsp"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

INHIBIT_DEFAULT_DEPS = "1"
PACKAGE_ARCH = "${MACHINE_ARCH}"

DEPENDS += "dtc-native"

FILES_${PN} = "/boot/devicetree*"
DEVICETREE_FLAGS ?= "-R 8 -p 0x3000"

KERNEL_DTS_INCLUDE_zynq = "${STAGING_KERNEL_DIR}/arch/arm/boot/dts ${STAGING_KERNEL_DIR}/arch/arm/boot/dts/include ${STAGING_KERNEL_DIR}/include"
KERNEL_DTS_INCLUDE_zynqmp = "${STAGING_KERNEL_DIR}/arch/arm/boot/dts ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/xilinx"

S = "${WORKDIR}"

python () {
    # auto add dependency on kernel tree
    if d.getVar("KERNEL_DTS_INCLUDE", True) != "":
        d.setVarFlag("do_compile", "depends",
            " ".join([d.getVarFlag("do_compile", "depends", True) or "", "virtual/kernel:do_shared_workdir"]))
}

do_compile() {
	for DTS_FILE in ${DEVICETREE}; do
		if test -n "${MACHINE_DEVICETREE}"; then
			mkdir -p ${WORKDIR}/devicetree
			for i in ${MACHINE_DEVICETREE}; do
				if test -e ${WORKDIR}/$i; then
					echo cp ${WORKDIR}/$i ${WORKDIR}/devicetree
					cp ${WORKDIR}/$i ${WORKDIR}/devicetree
				fi
			done
		fi

		DTS_NAME=`basename ${DTS_FILE} | awk -F "." '{print $1}'`
		for d in ${KERNEL_DTS_INCLUDE}; do
			dtc_include="${dtc_include} -i $d"
			cpp_include="${cpp_include} -I${d}"
		done
		${BUILD_CPP} -E -nostdinc -Ulinux -I${WORKDIR}/devicetree \
			${cpp_include} -x assembler-with-cpp \
			-o ${DTS_FILE}.pp ${DTS_FILE}
		dtc -I dts -O dtb ${DEVICETREE_FLAGS} -i ${WORKDIR}/devicetree \
			${dtc_include} -o ${DTS_NAME}.dtb ${DTS_FILE}.pp
	done
}

do_install() {
	for DTS_FILE in ${DEVICETREE}; do
		if [ ! -f ${DTS_FILE} ]; then
			echo "Warning: ${DTS_FILE} is not available!"
			continue
		fi
		DTS_NAME=`basename ${DTS_FILE} | awk -F "." '{print $1}'`
		install -d ${D}/boot/devicetree
		install -m 0644 ${B}/${DTS_NAME}.dtb ${D}/boot/devicetree/${DTS_NAME}.dtb
	done
}

do_deploy() {
	for DTS_FILE in ${DEVICETREE}; do
		if [ ! -f ${DTS_FILE} ]; then
			echo "Warning: ${DTS_FILE} is not available!"
			continue
		fi
		DTS_NAME=`basename ${DTS_FILE} | awk -F "." '{print $1}'`
		install -d ${DEPLOY_DIR_IMAGE}
		install -m 0644 ${B}/${DTS_NAME}.dtb ${DEPLOY_DIR_IMAGE}/${DTS_NAME}.dtb
		[ ${MACHINE}.dtb = ${DTS_NAME}.dtb ] || \
			ln -sf ${DTS_NAME}.dtb ${DEPLOY_DIR_IMAGE}/${MACHINE}.dtb
		ln -sf ${DTS_NAME}.dtb ${DEPLOY_DIR_IMAGE}/system.dtb
	done
}

# Deploy ${KERNEL_IMAGETYPE}-${DTS_NAME}.dtb for compatibility with runqemu
DEPLOY_KERNEL_DTB_qemuzynq = "1"
do_deploy_append() {
	if [ ! -z "${DEPLOY_KERNEL_DTB}" -a ! -z "${KERNEL_IMAGETYPE}" ]; then
		for DTS_FILE in ${DEVICETREE}; do
			DTS_NAME=`basename ${DTS_FILE} | awk -F "." '{print $1}'`
			KERNELDTBPATH=${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${DTS_NAME}.dtb
			if [ ! -e ${KERNELDTBPATH} -o -h ${KERNELDTBPATH} ]; then
				ln -sf ${DTS_NAME}.dtb ${KERNELDTBPATH}
			fi
		done
	fi
}

addtask deploy before do_build after do_install

inherit xilinx-utils

DEVICETREE ?= "${@expand_dir_basepaths_by_extension("MACHINE_DEVICETREE", os.path.join(d.getVar("WORKDIR", True), 'devicetree'), '.dts', d)}"
FILESEXTRAPATHS_append := "${@get_additional_bbpath_filespath('conf/machine/boards', d)}"

# Using the MACHINE_DEVICETREE and MACHINE_KCONFIG vars, append them to SRC_URI
SRC_URI += "${@paths_affix(d.getVar("MACHINE_DEVICETREE", True) or '', prefix = 'file://')}"

