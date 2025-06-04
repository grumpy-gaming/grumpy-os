################################################################################
#
# xdelta3
#
################################################################################

XDELTA3_VERSION = 3.1.0
XDELTA3_SITE = $(call github,jmacd,xdelta,v$(XDELTA3_VERSION))
XDELTA3_LICENSE = Apache-2.0
XDELTA3_LICENSE_FILES = COPYING
XDELTA3_SUBDIR = xdelta3
XDELTA3_AUTORECONF = YES
XDELTA3_DEPENDENCIES = host-pkgconf

# xdelta3 has optional dependencies that we can enable/disable
ifeq ($(BR2_PACKAGE_XDELTA3_LZMA),y)
XDELTA3_DEPENDENCIES += xz
XDELTA3_CONF_OPTS += --with-liblzma
else
XDELTA3_CONF_OPTS += --without-liblzma
endif

$(eval $(autotools-package))
