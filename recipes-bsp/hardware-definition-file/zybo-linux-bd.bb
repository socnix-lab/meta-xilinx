SUMMARY = "Xilinx Hardware Definition File for zybo-linux-bd"
DESCRIPTION = "Contains the Reference Design Files and hardware software hand-off files."
SECTION = "bsp"
DEPENDS += "unzip"

include hdf.inc

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://Projects/${HW_BD}/readme.txt;md5=e1cb7639bf00b6e730ff3a7f13714951"

COMPATIBLE_MACHINE = "zybo-linux-bd-zynq7"

HW_BD = "linux_bd"

# add branch support later
SRC_URI := "git://github.com/Digilent/ZYBO.git;protocol=https;nobranch=1"
SRCREV = "63ca49fe027da49f3b0ac636bd404fd31fbbd945"

PV = "+git${SRCPV}"

S = "${WORKDIR}/git"

HDF = "/Projects/${HW_BD}/hw_handoff/${HW_BD}_wrapper.hdf"
