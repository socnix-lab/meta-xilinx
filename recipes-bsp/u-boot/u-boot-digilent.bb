# To enable this recipe, set the following in your machine or local.conf
#   PREFERRED_PROVIDER_virtual/bootloader ?= "u-boot-digilent-2016.03"
#   PREFERRED_PROVIDER_u-boot ?= "u-boot-digilent-2016.03"

include u-boot-digilent.inc

# u-boot-digilent-dev : ${AUTOREV}
SRCREV_arty-z7-linux-bd-zynq7 = '${@oe.utils.conditional( \
	"PREFERRED_PROVIDER_virtual/bootloader","u-boot-digilent-dev", \
	"${AUTOREV}", "3b9fb2091625938a4f39750c16f990b8a4f9504a", d)}'
