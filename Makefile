GO_EASY_ON_ME := 1
ARCHS = armv7 arm64
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
THEOS_DEVICE_IP = 192.168.0.11

TWEAK_NAME = BadgeCleaner
BadgeCleaner_FILES = Tweak.xm BDCController.m
BadgeCleaner_FRAMEWORKS = UIKit

BUNDLE_NAME = BadgeCleanerSettings
BadgeCleanerSettings_FILES = Preference.m
BadgeCleanerSettings_INSTALL_PATH = /Library/PreferenceBundles
BadgeCleanerSettings_FRAMEWORKS = UIKit
BadgeCleanerSettings_PRIVATE_FRAMEWORKS = Preferences

SUBPROJECTS += BadgeCleanerSwitch

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BadgeCleaner.plist$(ECHO_END)

before-package::
	sudo chown -R root:wheel $(THEOS_STAGING_DIR)
	sudo chmod -R 755 $(THEOS_STAGING_DIR)
	sudo chmod 644 $(THEOS_STAGING_DIR)/Library/Switches/BadgeCleaner.bundle/*

after-install::
	install.exec "killall -9 SpringBoard"
	make clean
	sudo rm -rf ./*.zip
	sudo mv _ $(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm
	sudo rm -rf ./_
	zip -r $(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm.zip ./$(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm
	sudo rm -rf ./$(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm
	rm -rf .obj
	rm -rf obj
#	rm -rf .theos
#	rm -rf *.deb