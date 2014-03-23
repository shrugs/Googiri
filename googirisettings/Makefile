
ARCHS = armv7 arm64
TARGET := iphone:7.0:2.0
include theos/makefiles/common.mk

BUNDLE_NAME = GoogiriSettings
GoogiriSettings_FILES = GoogiriSettings.mm
GoogiriSettings_INSTALL_PATH = /Library/PreferenceBundles
GoogiriSettings_FRAMEWORKS = UIKit
GoogiriSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GoogiriSettings.plist$(ECHO_END)
