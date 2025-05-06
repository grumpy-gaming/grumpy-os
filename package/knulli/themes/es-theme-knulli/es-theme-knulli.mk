################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on May 05, 2025
ES_THEME_KNULLI_VERSION = a07867ae2afea6de36fcde4823226d8dc769614f
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
