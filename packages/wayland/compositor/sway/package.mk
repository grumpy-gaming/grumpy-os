# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="sway"
PKG_LICENSE="MIT"
PKG_SITE="https://swaywm.org/"
PKG_DEPENDS_TARGET="toolchain glib wayland wayland-protocols libdrm libxkbcommon libinput cairo pango libjpeg-turbo dbus json-c wlroots gdk-pixbuf swaybg foot bemenu xcb-util-wm xwayland xkbcomp xterm"
PKG_LONGDESC="i3-compatible Wayland compositor"
PKG_TOOLCHAIN="meson"

case ${DEVICE} in
  RK3588)
    PKG_VERSION="1.9"
    PKG_URL="https://github.com/swaywm/sway/archive/${PKG_VERSION}.zip"
  ;;
  *)
    PKG_VERSION="1.11-rc2"
    PKG_SHA256="78d24a4e0d2eb0e442155ca72afa924dba32a0e873456e8cf1e89155304c2590"
    PKG_URL="https://github.com/swaywm/sway/releases/download/${PKG_VERSION}/sway-${PKG_VERSION}.tar.gz"
  ;;
esac

# to enable xwayland package: https://gitlab.freedesktop.org/xorg/lib/libxcb-wm/-/tree/master/icccm?ref_type=heads

PKG_MESON_OPTS_TARGET="-Ddefault-wallpaper=false \
                       -Dzsh-completions=false \
                       -Dbash-completions=false \
                       -Dfish-completions=false \
                       -Dswaybar=true \
                       -Dswaynag=true \
                       -Dtray=disabled \
                       -Dgdk-pixbuf=enabled \
                       -Dman-pages=disabled \
                       -Dsd-bus-provider=auto"

pre_configure_target() {
  # sway does not build without -Wno flags as all warnings being treated as errors
  export TARGET_CFLAGS=$(echo "${TARGET_CFLAGS} -Wno-unused-variable")
}

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/sway
  mkdir -p ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/sway.sh     ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/sway-config ${INSTALL}/usr/lib/sway
  mkdir -p ${INSTALL}/usr/lib/autostart/common
    cp ${PKG_DIR}/autostart/111-sway-init     ${INSTALL}/usr/lib/autostart/common
    cp ${PKG_DIR}/scripts/sway-touch.sh     ${INSTALL}/usr/bin

  chmod +x ${INSTALL}/usr/bin/sway*

  # install config & wallpaper
  mkdir -p ${INSTALL}/usr/share/sway
    cp ${PKG_DIR}/config/* ${INSTALL}/usr/share/sway

  # clean up
  safe_remove ${INSTALL}/etc
  safe_remove ${INSTALL}/usr/share/wayland-sessions
}

post_install() {
  enable_service sway-touch.service
}
