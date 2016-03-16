# This recipe tracks the 'bleeding edge' linux-xlnx repository.
# Since this tree is frequently updated, AUTOREV is used to track its contents.
#
# To enable this recipe, set PREFERRED_PROVIDER_virtual/kernel = "linux-digilent-dev"

KBRANCH ?= "master"
SRCBRANCH = "${KBRANCH}"

# Use the SRCREV for the last tagged revision of linux-digilent.
# digilent-v2016.03 tag : "86b46b6606eea44c59af56b732e5393f2eb0adce"
# linux-digilent-dev : ${AUTOREV}
SRCREV ?= '${@oe.utils.conditional( \
	"PREFERRED_PROVIDER_virtual/kernel","linux-digilent-dev", \
	"${AUTOREV}", "86b46b6606eea44c59af56b732e5393f2eb0adce", d)}'

LINUX_VERSION ?= '${@oe.utils.conditional( \
	"PREFERRED_PROVIDER_virtual/kernel","linux-digilent-dev", \
	"4.0+", "4.0", d)}'
LINUX_VERSION_EXTENSION ?= '${@oe.utils.conditional( \
	"PREFERRED_PROVIDER_virtual/kernel","linux-digilent-dev", \
	"-digilent-dev", "-digilent", d)}'
PV ?= "${LINUX_VERSION}${LINUX_VERSION_EXTENSION}+git${SRCREV}"

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
