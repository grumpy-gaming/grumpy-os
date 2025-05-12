################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on May 12, 2025
ES_THEME_KNULLI_VERSION = dbde97d0e050661e241ebe702a6939f5ef9dd962
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
