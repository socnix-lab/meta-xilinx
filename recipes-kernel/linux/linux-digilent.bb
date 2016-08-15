# This recipe tracks the 'bleeding edge' linux-xlnx repository.
# Since this tree is frequently updated, AUTOREV is used to track its contents.
#
# To enable this recipe, set PREFERRED_PROVIDER_virtual/kernel = "linux-digilent-4.0"

include linux-digilent.inc

LINUX_VERSION_arty-z7-linux-bd-zynq7 = '4.4'
SRCREV_arty-z7-linux-bd-zynq7 = '${@oe.utils.conditional( \
	"PREFERRED_PROVIDER_virtual/kernel","linux-digilent-dev", \
	"${AUTOREV}", "879a2837b4877a3d535b085cdfc03e60aa0df7c6", d)}'
