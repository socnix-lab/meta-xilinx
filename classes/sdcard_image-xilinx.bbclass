# base on RPI sdcard_image-rpi.bbclass
#
inherit image_types
inherit xilinx-fitimage

#
# The default setting is design to work with U-Boot 2016.1 and after
#

#
# Create an image that can by written onto a SD card using dd.
#
# The disk layout used is:
#
#    0                      -> IMAGE_ROOTFS_ALIGNMENT         - reserved for other data
#    IMAGE_ROOTFS_ALIGNMENT -> BOOT_SPACE                     - bootloader and kernel
#    BOOT_SPACE             -> SDIMG_SIZE                     - rootfs
#

#                                                     Default Free space = 1.3x
#                                                     Use IMAGE_OVERHEAD_FACTOR to add more space
#                                                     <--------->
#            4MiB              40MiB           SDIMG_ROOTFS
# <-----------------------> <----------> <---------------------->
#  ------------------------ ------------ ------------------------
# | IMAGE_ROOTFS_ALIGNMENT | BOOT_SPACE | ROOTFS_SIZE            |
#  ------------------------ ------------ ------------------------
# ^                        ^            ^                        ^
# |                        |            |                        |
# 0                      4MiB     4MiB + 64MiB       4MiB + 64Mib + SDIMG_ROOTFS

# This image depends on the rootfs image
IMAGE_TYPEDEP_xilinx-sdimg = "${SDIMG_ROOTFS_TYPE}"

# Set kernel and boot loader
IMAGE_BOOTLOADER ?= "virtual/bootloader virtual/boot-bin"

# Kernel image name
SDIMG_KERNELIMAGE ?= "fit.itb"

# FIXME:
# There is a problem with the sd root. current the fit.itb's dtb is design
# to boot ramdisk not sd root. Thus, modification to sdroot is required.
# this can be done in few ways:
#  - create a separated dtb and fit image for sdroot - current used method
#  - allow u-boot to load uEnv.txt by default - preferred

# TODO: Proper way of handle this. Currenlty, append SDROOT_DTS_BOOTARG to
# end of dts bootargs. Not a ideal workaround.
SDROOT_DTS_BOOTARG ?= "root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait"

# Boot partition volume id
BOOTDD_VOLUME_ID ?= "BOOT"

# Boot partition size [in KiB] (will be rounded up to IMAGE_ROOTFS_ALIGNMENT)
BOOT_SPACE ?= "65536"

# Set alignment to 4MB [in KiB]
IMAGE_ROOTFS_ALIGNMENT = "4096"

# Use an uncompressed ext4 by default as rootfs
SDIMG_ROOTFS_TYPE ?= "ext4"
MACHINE_FEATURES += "${SDIMG_ROOTFS_TYPE}"
SDIMG_ROOTFS = "${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.${SDIMG_ROOTFS_TYPE}"

IMAGE_DEPENDS_xilinx-sdimg = " \
			dtc-native \
			parted-native \
			mtools-native \
			dosfstools-native \
			virtual/kernel \
			${IMAGE_BOOTLOADER} \
			"

# SD card image name
SDIMG = "${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.xilinx-sdimg"

# Compression method to apply to SDIMG after it has been created. Supported
# compression formats are "gzip", "bzip2" or "xz". The original .rpi-sdimg file
# is kept and a new compressed file is created if one of these compression
# formats is chosen. If SDIMG_COMPRESSION is set to any other value it is
# silently ignored.
#SDIMG_COMPRESSION ?= ""

# Additional files and/or directories to be copied into the vfat partition from the IMAGE_ROOTFS.
FATPAYLOAD ?= "${DEPLOY_DIR_IMAGE}/u-boot-dtb.img"

BITSTREAM ?= "${DEPLOY_DIR_IMAGE}/download.bit"

IMAGEDATESTAMP = "${@time.strftime('%Y.%m.%d',time.gmtime())}"

IMAGE_CMD_xilinx-sdimg () {

	# Align partitions
	BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
	BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ROOTFS_ALIGNMENT})
	SDIMG_SIZE=$(expr ${IMAGE_ROOTFS_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + $ROOTFS_SIZE)

	echo "Creating filesystem with Boot partition ${BOOT_SPACE_ALIGNED} KiB and RootFS $ROOTFS_SIZE KiB"

	# Initialize sdcard image file
	dd if=/dev/zero of=${SDIMG} bs=1024 count=0 seek=${SDIMG_SIZE}

	# Create partition table
	parted -s ${SDIMG} mklabel msdos
	# Create boot partition and mark it as bootable
	parted -s ${SDIMG} unit KiB mkpart primary fat32 ${IMAGE_ROOTFS_ALIGNMENT} $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT})
	parted -s ${SDIMG} set 1 boot on
	# Create rootfs partition to the end of disk
	parted -s ${SDIMG} -- unit KiB mkpart primary ext2 $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT}) -1s
	parted ${SDIMG} print

	# Create a vfat image with boot files
	BOOT_BLOCKS=$(LC_ALL=C parted -s ${SDIMG} unit b print | awk '/ 1 / { print substr($4, 1, length($4 -1)) / 512 /2 }')
	rm -f ${WORKDIR}/boot.img

	mkfs.vfat -n "${BOOTDD_VOLUME_ID}" -S 512 -C ${WORKDIR}/boot.img $BOOT_BLOCKS

	# Add stamp file
	echo "${IMAGE_NAME}-${IMAGEDATESTAMP}" > ${WORKDIR}/image-version-info
	mcopy -i ${WORKDIR}/boot.img -v ${WORKDIR}/image-version-info ::/

	# copy boot.bin to boot.img
	mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/boot.bin ::/

	cd ${WORKDIR}

	# create new dtb if SDROOT_DTS_BOOTARG is not empty
	# 1. convert system.dtb to system.dts
	# 2. rename system.dts -> base.dtsi
	# 3. create new dts that includes base.dtsi and change the
	#    bootarg setting
	# 4. create new dtb call sdroot-system.dtb
	# 5. generate new itb

	# look for dtb in ${DEPLOY_DIR_IMAGE} if default dtb found
	target_dtb=${DEPLOY_DIR_IMAGE}/${MACHINE}.dtb
	if [ ! -f ${target_dtb} ]; then
		target_dtb=$(find ${DEPLOY_DIR_IMAGE} --maxdepth 0 -name "*.dtb" | tail -1)
		if [ ! -f ${target_dtb} ]; then
			echo "Error: No dtb found!!!"
			exit 255
		fi
	fi

	if [ -n "${SDROOT_DTS_BOOTARG}" ]; then
		dtc -I dtb -O dts -o ${MACHINE}.dtsi ${target_dtb}
		# get the bootargs from dtsi
		bootargs=$(grep -r "bootargs" ${MACHINE}.dtsi | awk -F "bootargs" '{print $2}' | sed 's?[[:space:]]\{0,\}=[[:space:]]\{0,\}"??g' | awk -F '"' '{str=$1; for (i=2; i < NF; i++){str=str"\""$i}; print str}')

		sdroot_dts=sdroot-${MACHINE}.dts

		cat << EOF > ${sdroot_dts}
/include/ "${MACHINE}.dtsi"
/ {
	chosen {
		bootargs = "${bootargs} ${SDROOT_DTS_BOOTARG}";
	};
};
EOF

		dtc -I dts -O dtb -o sdroot-${MACHINE}.dtb ${sdroot_dts}
		install -m 0644 sdroot-${MACHINE}.dtb ${DEPLOY_DIR_IMAGE}
	else
		install -m 0644 $target_dtb sdroot-${MACHINE}.dtb
	fi

	do_assemble_xilinx_fitimage "" "-" "${WORKDIR}/sdroot-${MACHINE}.dtb"

	# copy fit.itb to boot.img
	mcopy -i ${WORKDIR}/boot.img -s ${WORKDIR}/fitImage ::${SDIMG_KERNELIMAGE}

	its_base_name="sdroot-${KERNEL_IMAGETYPE}-its-${PV}-${PR}-${MACHINE}"
	its_symlink_name=sdroot-${KERNEL_IMAGETYPE}-its-${MACHINE}
	install -m 0644 fit-image.its ${DEPLOY_DIR_IMAGE}/${its_base_name}.its
	ln -sf ${its_base_name}.its ${its_symlink_name}.its

	install -m 0644 fitImage ${DEPLOY_DIR_IMAGE}/sdroot-fitImage-${MACHINE}-${PV}-${PR}
	ln -sf sdroot-fitImage-${MACHINE}-${PV}-${PR} ${DEPLOY_DIR_IMAGE}/sdroot-fitImage

	if [ -n "${FATPAYLOAD}" ] ; then
		echo "Copying payload into VFAT"
		for entry in ${FATPAYLOAD} ; do
				# add the || true to stop aborting on vfat issues like not supporting .~lock files
				mcopy -i ${WORKDIR}/boot.img -s -v $entry :: || true
		done
	fi

	if [ -f ${BITSTREAM} ]; then
		mcopy -i ${WORKDIR}/boot.img -s -v ${BITSTREAM} :: || true
	fi

	# Burn Partitions
	dd if=${WORKDIR}/boot.img of=${SDIMG} conv=notrunc seek=1 bs=$(expr ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync

	# If SDIMG_ROOTFS_TYPE is a .xz file use xzcat
	if echo "${SDIMG_ROOTFS_TYPE}" | egrep -q "*\.xz"; then
		xzcat ${SDIMG_ROOTFS} | dd of=${SDIMG} conv=notrunc seek=1 bs=$(expr 1024 \* ${BOOT_SPACE_ALIGNED} + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
	else
		dd if=${SDIMG_ROOTFS} of=${SDIMG} conv=notrunc seek=1 bs=$(expr 1024 \* ${BOOT_SPACE_ALIGNED} + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
	fi

	# Optionally apply compression
	case "${SDIMG_COMPRESSION}" in
	"gzip")
		gzip -k9 "${SDIMG}"
		;;
	"bzip2")
		bzip2 -k9 "${SDIMG}"
		;;
	"xz")
		xz -k "${SDIMG}"
		;;
	esac
	ln -sf $(basename ${SDIMG}) ${DEPLOY_DIR_IMAGE}/sdimg-${MACHINE}
	ln -sf $(basename ${SDIMG}) ${DEPLOY_DIR_IMAGE}/sdimg
}
