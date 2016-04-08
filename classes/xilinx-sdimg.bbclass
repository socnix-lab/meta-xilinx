inherit image_types

DEPENDS = "parted-native dosfstools-native mtools-native"

IMAGE_TYPEDEP_wic = " \
	${@bb.utils.contains('IMAGE_FSTYPES', 'xilinx-fitimage', 'xilinx-fitimage', '',d)} \
"
WKS_FILE = "sdimage-xilinx.wks"

# align to 4MB
IMAGE_ROOTFS_ALIGNMENT = "4096"

# default of 1.3
# IMAGE_OVERHEAD_FACTOR = "1.3"
