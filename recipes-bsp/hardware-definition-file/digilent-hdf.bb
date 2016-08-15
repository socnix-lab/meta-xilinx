SUMMARY = "Xilinx Hardware Definition File for Digilent boards"
DESCRIPTION = "Contains the Reference Design Files and hardware software hand-off files."
SECTION = "bsp"
DEPENDS += "unzip"

include hdf.inc

LICENSE = "CLOSED"

COMPATIBLE_MACHINE = "(zybo-linux-bd-zynq7|arty-z7-linux-bd-zynq7)"

HW_BD = "linux_bd"

# add branch support later
SRC_URI := "git://github.com/Digilent/ZYBO.git;protocol=https;nobranch=1"
SRCREV = "63ca49fe027da49f3b0ac636bd404fd31fbbd945"

SRC_URI_arty-z7-linux-bd-zynq7 = "git://github.com/Digilent/Arty-Z7.git;protocol=https;nobranch=1"
SRCREV_arty-z7-linux-bd-zynq7 = "fdfe4800cac39a8b5707b7d5d8464ca9fac6135a"

PV = "+git${SRCPV}"

S = "${WORKDIR}/git"

HDF = "/Projects/${HW_BD}/hw_handoff/${HW_BD}_wrapper.hdf"
