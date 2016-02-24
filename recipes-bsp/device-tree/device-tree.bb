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

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append_zynq = " file://common/zynq7-base.dtsi"

S = "${WORKDIR}"

KERNEL_DTS_INCLUDE ??= ""
KERNEL_DTS_INCLUDE_zynq = "arch/arm/boot/dts/skeleton.dtsi arch/arm/boot/dts/zynq-7000.dtsi"
KERNEL_DTS_INCLUDE_zynqmp = "arch/arm/boot/dts/skeleton.dtsi arch/arm64/boot/dts/xilinx/zynqmp.dtsi"

python () {
    # auto add dependency on kernel tree
    if d.getVar("KERNEL_DTS_INCLUDE", True) != "":
        d.setVarFlag("do_compile", "depends",
            " ".join([d.getVarFlag("do_compile", "depends", True) or "", "virtual/kernel:do_shared_workdir"]))
}

do_compile() {
	for i in ${KERNEL_DTS_INCLUDE}; do
		DTSI_NAME=`basename $i`
		if test -e ${STAGING_KERNEL_DIR}/$i; then
			mkdir -p ${WORKDIR}/devicetree
			cp ${STAGING_KERNEL_DIR}/$i ${WORKDIR}/devicetree/${DTSI_NAME}
		fi
	done

	if test -n "${MACHINE_DEVICETREE}"; then
		mkdir -p ${WORKDIR}/devicetree
		for i in ${MACHINE_DEVICETREE}; do
			if test -e ${WORKDIR}/$i; then
				echo cp ${WORKDIR}/$i ${WORKDIR}/devicetree
				cp ${WORKDIR}/$i ${WORKDIR}/devicetree
			fi
		done
	fi

	for DTS_FILE in ${DEVICETREE}; do
		DTS_NAME=`basename -s .dts ${DTS_FILE}`
		dtc -I dts -O dtb ${DEVICETREE_FLAGS} -o ${DTS_NAME}.dtb ${DTS_FILE}
	done
}

do_install() {
	for DTS_FILE in ${DEVICETREE}; do
		if [ ! -f ${DTS_FILE} ]; then
			echo "Warning: ${DTS_FILE} is not available!"
			continue
		fi
		DTS_NAME=`basename -s .dts ${DTS_FILE}`
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
		DTS_NAME=`basename -s .dts ${DTS_FILE}`
		install -d ${DEPLOY_DIR_IMAGE}
		install -m 0644 ${B}/${DTS_NAME}.dtb ${DEPLOY_DIR_IMAGE}/${DTS_NAME}.dtb
		[ ${MACHINE}.dtb == ${DTS_NAME}.dtb ] || \
			ln -sf ${DTS_NAME}.dtb ${DEPLOY_DIR_IMAGE}/${MACHINE}.dtb
		ln -sf ${DTS_NAME}.dtb ${DEPLOY_DIR_IMAGE}/system.dtb
	done
}

# Deploy ${KERNEL_IMAGETYPE}-${DTS_NAME}.dtb for compatibility with runqemu
DEPLOY_KERNEL_DTB_qemuzynq = "1"
do_deploy_append() {
	if [ ! -z "${DEPLOY_KERNEL_DTB}" -a ! -z "${KERNEL_IMAGETYPE}" ]; then
		for DTS_FILE in ${DEVICETREE}; do
			DTS_NAME=`basename -s .dts ${DTS_FILE}`
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

