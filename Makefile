BUNDLE_ID    ?= org.muellerware.CopyPathname
VERSION      ?= 1.0.0
MIN_MACOS    ?= 13.0
ARCHS        ?= arm64 x86_64
# "-" is an ad-hoc signature; set to a "Developer ID Application: ..." identity to distribute.
SIGN_ID      ?= -
INSTALL_DIR  ?= $(HOME)/Applications

BUILD_DIR    := build
APP          := $(BUILD_DIR)/Copy Pathname.app
APPEX        := $(APP)/Contents/PlugIns/CopyPathnameExtension.appex
EXT_ID       := $(BUNDLE_ID).FinderExtension
LSREGISTER   := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
INSTALLED    := $(INSTALL_DIR)/Copy Pathname.app

SWIFTC_FLAGS := -O -swift-version 5

APP_SOURCES  := $(wildcard Sources/App/*.swift)
EXT_SOURCES  := $(wildcard Sources/Extension/*.swift)

SED_PLIST = sed -e 's/__BUNDLE_ID__/$(BUNDLE_ID)/g' \
                -e 's/__VERSION__/$(VERSION)/g' \
                -e 's/__MIN_MACOS__/$(MIN_MACOS)/g'

.PHONY: all build install uninstall enable disable status clean

all: build

build: $(APP_SOURCES) $(EXT_SOURCES) Resources/*
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS" "$(APPEX)/Contents/MacOS" $(BUILD_DIR)/obj

	@# Finder Sync extension
	for arch in $(ARCHS); do \
	  swiftc $(SWIFTC_FLAGS) -target $$arch-apple-macos$(MIN_MACOS) \
	    -parse-as-library -module-name CopyPathnameExtension \
	    -framework Cocoa -framework FinderSync \
	    -Xlinker -e -Xlinker _NSExtensionMain \
	    -o $(BUILD_DIR)/obj/ext-$$arch $(EXT_SOURCES) || exit 1; \
	done
	lipo -create $(addprefix $(BUILD_DIR)/obj/ext-,$(ARCHS)) \
	  -output "$(APPEX)/Contents/MacOS/CopyPathnameExtension"
	$(SED_PLIST) Resources/Extension-Info.plist > "$(APPEX)/Contents/Info.plist"

	@# Host app
	for arch in $(ARCHS); do \
	  swiftc $(SWIFTC_FLAGS) -target $$arch-apple-macos$(MIN_MACOS) \
	    -module-name CopyPathname \
	    -framework Cocoa -framework FinderSync \
	    -o $(BUILD_DIR)/obj/app-$$arch $(APP_SOURCES) || exit 1; \
	done
	lipo -create $(addprefix $(BUILD_DIR)/obj/app-,$(ARCHS)) \
	  -output "$(APP)/Contents/MacOS/CopyPathname"
	$(SED_PLIST) Resources/App-Info.plist > "$(APP)/Contents/Info.plist"

	@# Sign inside-out: extension first, then the containing app
	codesign --force --options runtime --timestamp=none --sign "$(SIGN_ID)" \
	  --entitlements Resources/Extension.entitlements "$(APPEX)"
	codesign --force --options runtime --timestamp=none --sign "$(SIGN_ID)" "$(APP)"
	codesign --verify --deep --strict "$(APP)"
	@echo "Built $(APP)"

install: build
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALLED)"
	cp -R "$(APP)" "$(INSTALL_DIR)/"
	$(LSREGISTER) -f "$(INSTALLED)"
	pluginkit -a "$(INSTALLED)/Contents/PlugIns/CopyPathnameExtension.appex"
	pluginkit -e use -i $(EXT_ID)
	@echo "Installed to $(INSTALLED)"

uninstall:
	-pluginkit -e ignore -i $(EXT_ID)
	-pluginkit -r "$(INSTALLED)/Contents/PlugIns/CopyPathnameExtension.appex"
	-$(LSREGISTER) -u "$(INSTALLED)"
	rm -rf "$(INSTALLED)"

enable:
	pluginkit -e use -i $(EXT_ID)

disable:
	pluginkit -e ignore -i $(EXT_ID)

status:
	pluginkit -m -v -i $(EXT_ID)

clean:
	rm -rf $(BUILD_DIR)
