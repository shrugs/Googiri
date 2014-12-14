
ARCHS = armv7 arm64

include theos/makefiles/common.mk

TWEAK_NAME = GoogiriSiriActivator
GoogiriSiriActivator_FILES = Tweak.xm
GoogiriSiriActivator_FRAMEWORKS = UIKit Foundation
GoogiriSiriActivator_LDFLAGS = -lactivator -lrocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk
