LINUX_VERSION = "4.4"
# Current bleeding edge of master linux-xlnx
# Will be updated to v4.4 kernel once it is released
SRCREV ?="c616730d3106d85367900420572f94f8c4c5386f"

include linux-xlnx.inc

SRC_URI_append_zybo-linux-bd-zynq7 = " \
	file://0001-drm-xilinx-Add-encoder-for-Digilent-boards.patch \
	file://0002-clk-Add-driver-for-axi_dynclk-IP-Core.patch \
"