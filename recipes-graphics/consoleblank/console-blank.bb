DESCRIPTION = "Startup script - disable console blank"
SECTION = "base"
LICENSE = "CLOSED"

PR = "r0"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = "file://console-blank"

inherit update-rc.d

INITSCRIPT_NAME = "console-blank"
INITSCRIPT_PARAMS = "start 39 S . stop 31 0 6 ."
#FILES_${PN} = "${sysconfdir}/init.d/console-blank"

# # # add to build if system machine supports screen
# PACKAGES += ' \
# 	${@bb.utils.contains("MACHINE_FEATURES", "screen", "console-blank", "",d)} \
# 	'

do_install () {
	install -d ${D}/${sysconfdir}/init.d/
	install -m 0755 ${WORKDIR}/console-blank ${D}${sysconfdir}/init.d/
}