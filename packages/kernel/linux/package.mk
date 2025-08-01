# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="linux"
PKG_LICENSE="GPL"
PKG_SITE="http://www.kernel.org"
PKG_DEPENDS_HOST="ccache:host rsync:host openssl:host"
PKG_DEPENDS_TARGET="linux:host kmod:host xz:host keyutils ncurses openssl:host ${KERNEL_EXTRA_DEPENDS_TARGET}"
PKG_NEED_UNPACK="${LINUX_DEPENDS} $(get_pkg_directory initramfs) $(get_pkg_variable initramfs PKG_NEED_UNPACK)"
PKG_NEED_UNPACK+=" ${PROJECT_DIR}/${PROJECT}/bootloader ${PROJECT_DIR}/${PROJECT}/devices/${DEVICE}/bootloader"
PKG_LONGDESC="This package contains a precompiled kernel image and the modules."
PKG_IS_KERNEL_PKG="yes"
PKG_STAMP="${KERNEL_TARGET} ${KERNEL_MAKE_EXTRACMD}"

PKG_PATCH_DIRS="${LINUX} mainline ${DEVICE} default"

case ${DEVICE} in
  RK3588)
    PKG_VERSION="b8e62bed74766b6c8c423a767b35495e78b64caf"
    PKG_URL="https://github.com/armbian/linux-rockchip/archive/${PKG_VERSION}.tar.gz"
    PKG_GIT_CLONE_BRANCH="rk-6.1-rkr3"
    PKG_PATCH_DIRS="${LINUX} ${DEVICE} default"
  ;;
  H700|SM8*)
    PKG_VERSION="6.15.2"
    PKG_URL="https://www.kernel.org/pub/linux/kernel/v${PKG_VERSION/.*/}.x/${PKG_NAME}-${PKG_VERSION}.tar.xz"
  ;;
  *)
    PKG_VERSION="6.12.29"
    PKG_URL="https://www.kernel.org/pub/linux/kernel/v${PKG_VERSION/.*/}.x/${PKG_NAME}-${PKG_VERSION}.tar.xz"
    PKG_PATCH_DIRS+=" 6.12-LTS"
  ;;
esac

PKG_KERNEL_CFG_FILE=$(kernel_config_path) || die

if [ -n "${KERNEL_TOOLCHAIN}" ]; then
  PKG_DEPENDS_TARGET+=" gcc-${KERNEL_TOOLCHAIN}:host"
  HEADERS_ARCH=${TARGET_ARCH}
else
  PKG_DEPENDS_TARGET+=" toolchain"
fi

if [ "${PKG_BUILD_PERF}" != "no" ] && grep -q ^CONFIG_PERF_EVENTS= ${PKG_KERNEL_CFG_FILE}; then
  PKG_BUILD_PERF="yes"
  PKG_DEPENDS_TARGET+=" binutils elfutils libunwind zlib openssl"
fi

if [[ "${TARGET_ARCH}" =~ i*86|x86_64 ]]; then
  PKG_DEPENDS_TARGET+=" elfutils:host pciutils"
  PKG_DEPENDS_UNPACK+=" intel-ucode kernel-firmware"
fi

# Ensure that the dependencies of initramfs:target are built correctly, but
# we don't want to add initramfs:target as a direct dependency as we install
# this "manually" from within linux:target
for pkg in $(get_pkg_variable initramfs PKG_DEPENDS_TARGET); do
  ! listcontains "${PKG_DEPENDS_TARGET}" "${pkg}" && PKG_DEPENDS_TARGET+=" ${pkg}" || true
done

if [ "${DEVICE}" = "RK3326" -o "${DEVICE}" = "RK3566" ]; then
  PKG_DEPENDS_UNPACK+=" generic-dsi"
elif [ "${DEVICE}" = "SM8250" -o "${DEVICE}" = "H700" ]; then
  PKG_DEPENDS_UNPACK+=" kernel-firmware"
fi

post_patch() {
  # linux was already built and its build dir autoremoved - prepare it again for kernel packages
  if [ -d ${PKG_INSTALL}/.image ]; then
    cp -p ${PKG_INSTALL}/.image/.config ${PKG_BUILD}
    kernel_make -C ${PKG_BUILD} prepare

    # restore the required Module.symvers from an earlier build
    cp -p ${PKG_INSTALL}/.image/Module.symvers ${PKG_BUILD}
  fi

  if [ "${DEVICE}" = "RK3326" -o "${DEVICE}" = "RK3566" ]; then
    cp -v $(get_pkg_directory generic-dsi)/sources/panel-generic-dsi.c ${PKG_BUILD}/drivers/gpu/drm/panel/
    echo "obj-y" += panel-generic-dsi.o >> ${PKG_BUILD}/drivers/gpu/drm/panel/Makefile
  fi
}

make_init() {
 : # reuse make_target()
}

makeinstall_init() {
  :
}

make_host() {
  :
}

makeinstall_host() {
  make \
    ARCH=${HEADERS_ARCH:-${TARGET_KERNEL_ARCH}} \
    HOSTCC="${TOOLCHAIN}/bin/host-gcc" \
    HOSTCXX="${TOOLCHAIN}/bin/host-g++" \
    HOSTCFLAGS="${HOST_CFLAGS}" \
    HOSTCXXFLAGS="${HOST_CXXFLAGS}" \
    HOSTLDFLAGS="${HOST_LDFLAGS}" \
    INSTALL_HDR_PATH=dest \
    headers_install
  mkdir -p ${SYSROOT_PREFIX}/usr/include
    cp -R dest/include/* ${SYSROOT_PREFIX}/usr/include
}

pre_make_target() {
  ( cd ${ROOT}
    rm -rf ${BUILD}/initramfs
    rm -f ${STAMPS_INSTALL}/initramfs/install_target ${STAMPS_INSTALL}/*/install_init
    ${SCRIPTS}/install initramfs
  )
  pkg_lock_status "ACTIVE" "linux:target" "build"

  cp ${PKG_KERNEL_CFG_FILE} ${PKG_BUILD}/.config

  # set initramfs source
  ${PKG_BUILD}/scripts/config --set-str CONFIG_INITRAMFS_SOURCE "$(kernel_initramfs_confs) ${BUILD}/initramfs"

  # set default hostname based on ${DEVICE}
  ${PKG_BUILD}/scripts/config --set-str CONFIG_DEFAULT_HOSTNAME "${DEVICE}"

  # disable swap support if not enabled
  if [ ! "${SWAP_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_SWAP
  fi

  # enable / disable zram support (zstd compression) as required
  if [ "${SWAP_TYPE}" = zram ]; then
    ${PKG_BUILD}/scripts/config --module CONFIG_ZRAM
    ${PKG_BUILD}/scripts/config --enable CONFIG_ZRAM_BACKEND_ZSTD
    ${PKG_BUILD}/scripts/config --enable CONFIG_ZRAM_DEF_COMP_ZSTD
    ${PKG_BUILD}/scripts/config --set-val CONFIG_ZRAM_DEF_COMP "zstd"
  else
    ${PKG_BUILD}/scripts/config --disable CONFIG_ZRAM
  fi

  # disable nfs support if not enabled
  if [ "${NFS_SUPPORT}" = no ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_NFS_FS
  fi

  # disable cifs support if not enabled
  if [ ! "${SAMBA_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_CIFS
  fi

  # disable iscsi support if not enabled
  if [ ! "${ISCSI_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_SCSI_ISCSI_ATTRS
    ${PKG_BUILD}/scripts/config --disable CONFIG_ISCSI_TCP
    ${PKG_BUILD}/scripts/config --disable CONFIG_ISCSI_BOOT_SYSFS
    ${PKG_BUILD}/scripts/config --disable CONFIG_ISCSI_IBFT_FIND
    ${PKG_BUILD}/scripts/config --disable CONFIG_ISCSI_IBFT
  fi

  # disable lima/panfrost if libmali is configured
  if [ "${OPENGLES}" = "libmali" ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_DRM_LIMA
    ${PKG_BUILD}/scripts/config --disable CONFIG_DRM_PANFROST
  fi

  # disable wireguard support if not enabled
  if [ ! "${WIREGUARD_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_WIREGUARD
  fi

  if [[ "${TARGET_ARCH}" =~ i*86|x86_64 ]]; then
    # copy some extra firmware to linux tree
    mkdir -p ${PKG_BUILD}/external-firmware
      cp -a $(get_build_dir kernel-firmware)/.copied-firmware/{amdgpu,amd-ucode,i915,radeon,e100,rtl_nic} ${PKG_BUILD}/external-firmware

    cp -a $(get_build_dir intel-ucode)/intel-ucode ${PKG_BUILD}/external-firmware

    FW_LIST="$(find ${PKG_BUILD}/external-firmware \( -type f -o -type l \) \( -iname '*.bin' -o -iname '*.fw' -o -path '*/intel-ucode/*' \) | sed 's|.*external-firmware/||' | sort | xargs)"

    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE "${FW_LIST}"
    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE_DIR "external-firmware"
  elif [ "${TARGET_ARCH}" = "aarch64" -a "${DEVICE}" = "SM8250" ]; then
    mkdir -p ${PKG_BUILD}/external-firmware/qcom/sm8250
    mkdir -p ${PKG_BUILD}/external-firmware/qcom/vpu-1.0
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/qcom/a650_gmu.bin ${PKG_BUILD}/external-firmware/qcom
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/qcom/a650_sqe.fw ${PKG_BUILD}/external-firmware/qcom
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/qcom/sm8250/a650_zap.mbn ${PKG_BUILD}/external-firmware/qcom/sm8250
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/qcom/sm8250/adsp.mbn ${PKG_BUILD}/external-firmware/qcom/sm8250
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/qcom/sm8250/cdsp.mbn ${PKG_BUILD}/external-firmware/qcom/sm8250
      cp $(get_build_dir kernel-firmware)/.copied-firmware/qcom/sm8250/Thundercomm/RB5/* $(get_build_dir kernel-firmware)/.copied-firmware/qcom/sm8250/
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/qcom/sm8250/slpi.mbn ${PKG_BUILD}/external-firmware/qcom/sm8250

    FW_LIST="$(find ${PKG_BUILD}/external-firmware -type f | sed 's|.*external-firmware/||' | sort | xargs)"

    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE "${FW_LIST}"
    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE_DIR "external-firmware"
  elif [ "${TARGET_ARCH}" = "aarch64" -a "${DEVICE}" = "H700" ]; then
    mkdir -p ${PKG_BUILD}/external-firmware/rtl_bt
    mkdir -p ${PKG_BUILD}/external-firmware/rtw88
    mkdir -p ${PKG_BUILD}/external-firmware/panels
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/rtl_bt/rtl8821cs_config.bin ${PKG_BUILD}/external-firmware/rtl_bt
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/rtl_bt/rtl8821cs_fw.bin ${PKG_BUILD}/external-firmware/rtl_bt
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/rtw88/rtw8821c_fw.bin ${PKG_BUILD}/external-firmware/rtw88
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/panels/anbernic,rg28xx-panel.panel ${PKG_BUILD}/external-firmware/panels
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/panels/anbernic,rg34xx-panel.panel ${PKG_BUILD}/external-firmware/panels
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/panels/anbernic,rg34xx-sp-panel.panel ${PKG_BUILD}/external-firmware/panels
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/panels/anbernic,rg35xx-plus-panel.panel ${PKG_BUILD}/external-firmware/panels
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/panels/anbernic,rg35xx-plus-rev6-panel.panel ${PKG_BUILD}/external-firmware/panels
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/panels/anbernic,rg35xx-sp-v2-panel.panel ${PKG_BUILD}/external-firmware/panels
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/panels/anbernic,rg40xx-panel.panel ${PKG_BUILD}/external-firmware/panels
      cp -Lv $(get_build_dir kernel-firmware)/.copied-firmware/panels/anbernic,rgcubexx-panel.panel ${PKG_BUILD}/external-firmware/panels

    FW_LIST="$(find ${PKG_BUILD}/external-firmware -type f | sed 's|.*external-firmware/||' | sort | xargs)"

    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE "${FW_LIST}"
    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE_DIR "external-firmware"
  fi

  kernel_make listnewconfig
  if [ "${INTERACTIVE_CONFIG}" = "yes" ]; then
    # manually answer .config changes
    kernel_make oldconfig
  elif [ "${INTERACTIVE_CONFIG}" = "menuconfig" ]; then
    # manually answer .config changes
    kernel_make menuconfig
  else
    # accept default answers for .config changes
    yes "" | kernel_make oldconfig > /dev/null
  fi

  if [ -f "${DISTRO_DIR}/${DISTRO}/kernel_options" ]; then
    while read OPTION; do
      [ -z "${OPTION}" -o -n "$(echo "${OPTION}" | grep '^#')" ] && continue

      if [ "${OPTION##*=}" == "n" -a "$(${PKG_BUILD}/scripts/config --state ${OPTION%%=*})" == "undef" ]; then
        continue
      fi

      if [ "$(${PKG_BUILD}/scripts/config --state ${OPTION%%=*})" != "$(echo ${OPTION##*=} | tr -d '"')" ]; then
        MISSING_KERNEL_OPTIONS+="\t${OPTION}\n"
      fi
    done < ${DISTRO_DIR}/${DISTRO}/kernel_options

    if [ -n "${MISSING_KERNEL_OPTIONS}" ]; then
      print_color CLR_WARNING "LINUX: kernel options not correct: \n${MISSING_KERNEL_OPTIONS%%}\nPlease run ./tools/check_kernel_config\n"
    fi
  fi
}

make_target() {
  DTC_FLAGS=-@ kernel_make ${KERNEL_TARGET} ${KERNEL_MAKE_EXTRACMD} modules

  if [ "${PKG_BUILD_PERF}" = "yes" ]; then
    ( cd tools/perf

      # arch specific perf build args
      case "${TARGET_ARCH}" in
        x86_64|i*86)
          PERF_BUILD_ARGS="ARCH=x86"
          ;;
        aarch64)
          PERF_BUILD_ARGS="ARCH=arm64"
          ;;
        *)
          PERF_BUILD_ARGS="ARCH=${TARGET_ARCH}"
          ;;
      esac

      WERROR=0 \
      NO_LIBPERL=1 \
      NO_LIBPYTHON=1 \
      NO_SLANG=1 \
      NO_GTK2=1 \
      NO_LIBNUMA=1 \
      NO_LIBAUDIT=1 \
      NO_LIBTRACEEVENT=1 \
      NO_LZMA=1 \
      NO_SDT=1 \
      CROSS_COMPILE="${TARGET_PREFIX}" \
      JOBS="${CONCURRENCY_MAKE_LEVEL}" \
        make ${PERF_BUILD_ARGS}
      mkdir -p ${INSTALL}/usr/bin
        cp perf ${INSTALL}/usr/bin
    )
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/.image
  cp -p arch/${TARGET_KERNEL_ARCH}/boot/${KERNEL_TARGET} System.map .config Module.symvers ${INSTALL}/.image/

  kernel_make INSTALL_MOD_PATH=${INSTALL}/$(get_kernel_overlay_dir) modules_install
  rm -f ${INSTALL}/$(get_kernel_overlay_dir)/lib/modules/*/build
  rm -f ${INSTALL}/$(get_kernel_overlay_dir)/lib/modules/*/source

  if [ "${BOOTLOADER}" = "u-boot" -o "${BOOTLOADER}" = "arm-efi" ]; then
    mkdir -p ${INSTALL}/usr/share/bootloader
    for dtb in arch/${TARGET_KERNEL_ARCH}/boot/dts/*.dtb arch/${TARGET_KERNEL_ARCH}/boot/dts/*/*.dtb; do
      if [ -f ${dtb} ]; then
        if [ "${PROJECT}" = "Allwinner" -o "${PROJECT}" = "Rockchip" ]; then
          mkdir -p ${INSTALL}/usr/share/bootloader/device_trees
          cp -v ${dtb} ${INSTALL}/usr/share/bootloader/device_trees
        else
          cp -v ${dtb} ${INSTALL}/usr/share/bootloader
        fi
      fi
    done
  fi
  makeinstall_host
}
