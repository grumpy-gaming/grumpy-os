################################################################################
#
# rtkbtusb: Realtek Bluetooth USB driver (rtk_btusb) out‑of‑tree module
#

RTKBTUSB_VERSION         = main
RTKBTUSB_SITE            = $(call github,radxa,rtkbt,$(RTKBTUSB_VERSION))
RTKBTUSB_SITE_METHOD     = git
RTKBTUSB_LICENSE         = BSD-3-Clause
RTKBTUSB_LICENSE_FILES   = LICENSE
RTKBTUSB_DEPENDENCIES    = linux

# Tell the kernel buildsystem to build only usb/ as a module
RTKBTUSB_MODULE_MAKE_OPTS = \
    CONFIG_RTKBT_USB=m

define RTKBTUSB_MAKE_SUBDIR
	(cd $(@D); ln -s usb/bluetooth_usb_driver rtkbtusb)
endef

RTKBTUSB_PRE_CONFIGURE_HOOKS += RTKBTUSB_MAKE_SUBDIR

# Install the .ko into the kernel modules tree, then copy all firmware blobs
define RTKBTUSB_INSTALL_TARGET_CMDS
	# 1) kernel module
	$(INSTALL) -D -m 0644 \
	  $(@D)/rtk_btusb.ko \
	  $(TARGET_DIR)/lib/modules/$(LINUX_KERNEL_VERSION)/kernel/drivers/bluetooth/rtk_btusb.ko

	# 2) Realtek firmware
	$(INSTALL) -d $(TARGET_DIR)/lib/firmware/
	$(INSTALL) -m 0644 \
	  $(@D)/rtkbt-firmware/lib/firmware/rtl8723* \
	  $(TARGET_DIR)/lib/firmware/
endef

# Register with Buildroot’s module infrastructure
$(eval $(kernel-module))
$(eval $(generic-package))

