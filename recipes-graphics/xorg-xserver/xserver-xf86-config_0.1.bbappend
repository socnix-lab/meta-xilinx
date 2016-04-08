FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

# install 20-disable-screen-saver.conf if console-blank is installed
SRC_URI_append_zynq = ' \
	${@bb.utils.contains("IMAGE_INSTALL", "console-blank", "file://xorg.conf.d/20-disable-screen-saver.conf", "",d)} \
	'

do_install_append_zynq () {
	install -d ${D}/${sysconfdir}/X11/xorg.conf.d/
	install -m 0644 ${WORKDIR}/xorg.conf.d/* ${D}/${sysconfdir}/X11/xorg.conf.d/
}