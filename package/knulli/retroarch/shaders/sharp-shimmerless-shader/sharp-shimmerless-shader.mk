################################################################################
#
# sharp-shimmerless-shaders
#
################################################################################
# Version: Commits on Nov 24, 2024
SHARP_SHIMMERLESS_SHADER_VERSION = 2a74e7af599335c2ce5e493f823a757925c80db3
SHARP_SHIMMERLESS_SHADER_SITE = $(call github,Woohyun-Kang,Sharp-Shimmerless-Shader,$(SHARP_SHIMMERLESS_SHADER_VERSION))
SHARP_SHIMMERLESS_SHADER_LICENSE = GPL

define SHARP_SHIMMERLESS_SHADER_INSTALL_TARGET_CMDS
  mkdir -p $(TARGET_DIR)/usr/share/batocera/shaders/sharp-shimmerless
  cp -rf $(@D)/shaders_glsl         $(TARGET_DIR)/usr/share/batocera/shaders/sharp-shimmerless
  cp -rf $(@D)/shaders_slang        $(TARGET_DIR)/usr/share/batocera/shaders/sharp-shimmerless
endef

$(eval $(generic-package))
