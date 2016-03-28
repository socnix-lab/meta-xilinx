inherit image_types

#
# Based on kernel-fitimage recipe.
# Create an fitImage image that contents:
#	- 1 kernel image
#	- 1 rootfs image
#	- 1 dtb image
#	- 1 configuration
# limitations:
#	- no multiple image/config support
#

# This image depends on the rootfs image
IMAGE_TYPEDEP_xilinx-fitimage = "${FITIMAGE_ROOTFS_TYPE}"

# Use an uncompressed cpio by default as rootfs
FITIMAGE_ROOTFS_TYPE ?= "cpio"
FITIMAGE_ROOTFS_COMPRESSION_TYPE ?= "none"
FITIMAGE_ROOTFSIMG ?= "${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.${FITIMAGE_ROOTFS_TYPE}"

FITIMAGE_KERNELIMG ?= "${DEPLOY_DIR_IMAGE}/linux.bin"
FITIMAGE_KERNEL_COMPRESSION_TYPE ?= "none"
FITIMAGE_KERNEL_ENTRYPOINT ?= "0x8000"
FITIMAGE_KERNEL_LOADADDRESS ?= "0x8000"

FITIMAGE_DTBIMG ?= "${DEPLOY_DIR_IMAGE}/${MACHINE}.dtb"

IMAGE_DEPENDS_xilinx-fitimage = " \
			u-boot-mkimage-native \
			dtc-native \
			device-tree \
			virtual/kernel \
			"

# Final fitimage name
FITIMAGE_NAME ?= "fit.itb"

IMAGE_CMD_xilinx-fitimage () {
	cd ${B}
	do_assemble_xilinx_fitimage

	echo "Copying fit-image.its source file..."
	fitimg_bn=fitImage-${PV}-${PR}-${MACHINE}
	its_base_name="${KERNEL_IMAGETYPE}-its-${PV}-${PR}-${MACHINE}"
	its_symlink_name=${KERNEL_IMAGETYPE}-its-${MACHINE}
	install -m 0644 fit-image.its ${DEPLOY_DIR_IMAGE}/${its_base_name}.its
	install -m 0644 fitImage ${DEPLOY_DIR_IMAGE}/${fitimg_bn}

	ln -sf ${fitimg_bn} ${DEPLOY_DIR_IMAGE}/${FITIMAGE_NAME}
	ln -sf ${its_base_name}.its ${DEPLOY_DIR_IMAGE}/${its_symlink_name}.its
}

inherit kernel-fitimage

#
# Emit the fitImage ITS image checksume section
#
# $@ ... checksum algorithm
fitimage_emit_section_cksum() {
	csum_list=$@
	count=1
	for csum in ${csum_list}; do
		cat << EOF >> fit-image.its
                        hash@${count} {
                                algo = "${csum}";
                        };
EOF
		count=`expr ${count} + 1`
	done
}

#
# Emit the fitImage ITS kernel section
#
# $1 ... Image counter
# $2 ... Path to kernel image
# $3 ... Compression type
# $4 ... checksum algorithm
fitimage_emit_section_kernel() {
	kernel_csum=${4:-"sha1"}

	cat << EOF >> fit-image.its
                kernel@${1} {
                        description = "Linux kernel";
                        data = /incbin/("${2}");
                        type = "kernel";
                        arch = "${UBOOT_ARCH}";
                        os = "linux";
                        compression = "${3}";
                        load = <${FITIMAGE_KERNEL_ENTRYPOINT}>;
                        entry = <${FITIMAGE_KERNEL_ENTRYPOINT}>;
EOF
	fitimage_emit_section_cksum ${kernel_csum}

	echo "                };" >> fit-image.its
}

#
# Emit the fitImage ITS kernel section
#
# $1 ... Image counter
# $2 ... Path to rootfs image
# $3 ... Compression type
# $4 ... checksum algorithm
fitimage_emit_section_rootfs() {
	rootfs_csum=${4:-"sha1"}

	cat << EOF >> fit-image.its
                ramdisk@${1} {
                        description = "${UBOOT_ARCH} ${MACHINE} ramdisk";
                        data = /incbin/("${2}");
                        type = "ramdisk";
                        arch = "${UBOOT_ARCH}";
                        os = "linux";
                        compression = "${3}";
EOF
	fitimage_emit_section_cksum ${rootfs_csum}

	echo "                };" >> fit-image.its
}

#
# Emit the fitImage ITS configuration section
#
# $1 ... Linux kernel ID
# $2 ... DTB image ID
# $3 ... rootfs image ID
fitimage_emit_section_config() {
	conf_csum="sha1"

	# Test if we have any DTBs at all
	if [ -z "${2}" ] ; then
		conf_desc="Boot Linux kernel"
		fdt_line=""
	else
		conf_desc="Boot Linux kernel with FDT blob"
		fdt_line="fdt = \"fdt@${2}\";"
	fi

	# Test if we have any ROOTFS at all
	if [ -n "${3}" ] ; then
		conf_desc="$conf_desc + ramdisk"
		fdt_line="${fdt_line}
                        ramdisk = \"ramdisk@${3}\";"
	fi

	kernel_line="kernel = \"kernel@${1}\";"

	cat << EOF >> fit-image.its
                default = "conf@1";
                conf@1 {
                        description = "${conf_desc}";
                        ${kernel_line}
                        ${fdt_line}
                        hash@1 {
                                algo = "${conf_csum}";
                        };
                };
EOF
}

do_assemble_xilinx_fitimage() {
	kernel_img=${1:-${FITIMAGE_KERNELIMG}}
	rootfs_img=${2:-${FITIMAGE_ROOTFSIMG}}
	dtb_img=${3:-${FITIMAGE_DTBIMG}}

	rm -f fit-image.its

	fitimage_emit_fit_header

	fitimage_emit_section_maint imagestart

	#
	# Step 1: Prepare a kernel image section.
	#
	kernelcount=1
	fitimage_emit_section_kernel ${kernelcount} \
		${kernel_img} \
		${FITIMAGE_KERNEL_COMPRESSION_TYPE} \
		${FITIMAGE_KERNEL_CSUM}

	#
	# Step 2: Prepare a ramdisk image section
	#
	if [ "${rootfs_img}" != "-" ]; then
		rdcount=1
		fitimage_emit_section_rootfs ${rdcount} \
			${rootfs_img} \
			${FITIMAGE_ROOTFS_COMPRESSION_TYPE} \
			${FITIMAGE_ROOTFS_CSUM}
	fi

	#
	# Step 3: Prepare a DTB image section
	#
	dtbcount=1
	fitimage_emit_section_dtb ${dtbcount} ${dtb_img} \
		${FITIMAGE_DTBIMG_CSUM}

	fitimage_emit_section_maint sectend

	#
	# Step 4: Prepare a configurations section
	#
	fitimage_emit_section_maint confstart
	fitimage_emit_section_config ${kernelcount} ${dtbcount} ${rdcount}

	fitimage_emit_section_maint sectend

	fitimage_emit_section_maint fitend

	#
	# Step 4: Assemble the image
	#
	uboot-mkimage -f fit-image.its fitImage
}
