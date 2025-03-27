################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on March 27, 2025
ES_THEME_KNULLI_VERSION = f9136e9b0cfa426c5e0f31809e11690728a3e43a
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
