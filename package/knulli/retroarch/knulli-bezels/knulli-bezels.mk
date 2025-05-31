################################################################################
#
# knulli bezels
#
################################################################################
# Version.: Commits on May 31, 2025
KNULLI_BEZELS_VERSION = efb5612b292193f13e9f3c4bb15f0e5ebe5f505e
KNULLI_BEZELS_SITE = $(call github,chrizzo-hb,knulli-bezels,$(KNULLI_BEZELS_VERSION))

define KNULLI_BEZELS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	cp -rf $(@D)/default-knulli		      $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	cp -rf $(@D)/default-knulli-sp	      $(TARGET_DIR)/usr/share/batocera/datainit/decorations
	(cd $(TARGET_DIR)/usr/share/batocera/datainit/decorations && ln -sf default-knulli default)

endef

$(eval $(generic-package))
