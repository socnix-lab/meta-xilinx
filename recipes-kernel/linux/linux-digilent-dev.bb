# This recipe tracks the 'bleeding edge' linux-xlnx repository.
# Since this tree is frequently updated, AUTOREV is used to track its contents.
#
# To enable this recipe, set PREFERRED_PROVIDER_virtual/kernel = "linux-digilent-dev"

KBRANCH ?= "master"
SRCBRANCH = "${KBRANCH}"

# Use the SRCREV for the last tagged revision of linux-digilent.
SRCREV = "${AUTOREV}"

LINUX_VERSION = "4.0+"
LINUX_VERSION_EXTENSION ?= "-digilent-dev"
PV = "${LINUX_VERSION}${LINUX_VERSION_EXTENSION}+git${SRCREV}"

include linux-xlnx.inc

KERNEL_URI = " \
	git://github.com/Digilent/linux-digilent.git;protocol=https;branch=${KBRANCH} \
	"

SRC_URI = " \
	${KERNEL_URI} \
	file://xilinx-base;type=kmeta;destsuffix=xilinx-base \
	"

kernel_do_deploy_append() {
	cd ${B}
	uboot_prep_kimage
	linux_bin_basename="${KERNEL_IMAGETYPE}-linux.bin-${PV}-${PR}-${MACHINE}"
	install -m 0644 linux.bin ${DEPLOYDIR}/${linux_bin_basename}.bin

	cd ${DEPLOYDIR}
	ln -sf ${linux_bin_basename}.bin linux.bin
}
