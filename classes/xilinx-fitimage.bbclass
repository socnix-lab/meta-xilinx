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

do_assemble_xilinx_fitimage() {
	${XILINXBASE}/scripts/bin/mkits.sh -v "${MACHINE}" \
		-k "${FITIMAGE_KERNELIMG}" -c 1 \
		-C "${FITIMAGE_KERNEL_COMPRESSION_TYPE}" \
		-e "${FITIMAGE_KERNEL_ENTRYPOINT}" \
		-a "${FITIMAGE_KERNEL_LOADADDRESS}" \
		-r "${FITIMAGE_ROOTFSIMG}" -c 1 \
		-C "${FITIMAGE_ROOTFS_COMPRESSION_TYPE}" \
		-d "${FITIMAGE_DTBIMG}" -c 1 \
		-o fit-image.its
	uboot-mkimage -f fit-image.its fitImage
}
