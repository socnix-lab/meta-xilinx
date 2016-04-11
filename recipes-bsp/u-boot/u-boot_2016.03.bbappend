include u-boot-spl-zynq-init.inc

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
SRC_URI_append_picozed-zynq7 = " file://ARM-zynq-Configure-picozed-to-use-custom-init.patch"

SRC_URI_append_zybo-linux-bd-zynq7 = " file://uEnv.txt"

UBOOT_ENV_zybo-linux-bd-zynq7 = "uEnv"

SRC_URI_append = " file://zynq-Add-fpga-support-to-u-boot-SPL.patch \
		file://configs-zynq-common-Add-uEnv.txt-support.patch \
"

# u-boot 2016.03 has support for these
HAS_PS7INIT ?= " \
		zynq_microzed_config \
		zynq_zed_config \
		zynq_zc702_config \
		zynq_zc706_config \
		zynq_zybo_config \
		"

