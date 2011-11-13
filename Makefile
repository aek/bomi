# DYLD_FALLBACK_LIBRARY_PATH /Applications/VLC.app/Contents/MacOS/lib

kern := $(shell uname -s)
os := $(shell if test $(kern) = "Darwin"; then echo "osx"; elif test $(kern) = "Linux"; then echo "linux"; else echo "unknown"; fi)
qmake_vars := DESTDIR=\\\"../../bin\\\" RELEASE=\\\"yes\\\"
vlc_plugins_dir := vlc-plugins
install_file := install -m 644
install_exe := install -m 755
install_dir := sh install_dir.sh
configured := $(shell cat configured)

ifeq ($(os),osx)
	QTSDK ?= /Developer/QtSDKs/Desktop/Qt/474/gcc
	QMAKE ?= $(QTSDK)/bin/qmake -spec macx-g++
	MACDEPLOYQT ?= $(QTSDK)/bin/macdeployqt
	LRELEASE ?= $(QTSDK)/bin/lrelease
	VLC_INCLUDE_PATH ?= /Applications/VLC.app/Contents/MacOS/include
	VLC_LIB_PATH ?= /Applications/VLC.app/Contents/MacOS/lib
	VLC_PLUGINS_PATH ?= /Applications/VLC.app/Contents/MacOS/plugins
	cmplayer_exec := CMPlayer
	cmplayer_exec_path := bin/$(cmplayer_exec).app/Contents/MacOS
	qmake_vars := $(qmake_vars) \
		VLC_INCLUDE_PATH=\\\"$(VLC_INCLUDE_PATH)\\\" VLC_LIB_PATH=$(VLC_LIB_PATH)
	copy_qt = \
		install -d $(cmplayer_exec_path)/../Frameworks/$@.framework/Versions/4 && \
		$(install_file) $(QTSDK)/lib/$@.framework/Versions/4/$@ \
			$(cmplayer_exec_path)/../Frameworks/$@.framework/Versions/4/$@ && \
		install_name_tool -change $(QTSDK)/lib/$@.framework/Versions/Current/$@ \
			@executable_path/../Frameworks/$@.framework/Versions/4/$@
else
	PREFIX ?= /usr/local
	QMAKE ?= qmake
	LRELEASE ?= lrelease
	BIN_PATH ?= $(PREFIX)/bin
	DATA_PATH ?= $(PREFIX)/share
	ICON_PATH ?= $(DATA_PATH)/icons/hicolor
	APP_PATH ?= $(DATA_PATH)/applications
	ACTION_PATH ?= $(DATA_PATH)/apps/solid/actions
	CMPLAYER_VLC_PLUGINS_PATH ?= $(PREFIX)/lib/cmplayer/$(vlc_plugins_dir)
#	CMPLAYER_SKIN_PATH ?= $(DATA_PATH)/cmplayer/skin
	cmplayer_exec := cmplayer
	qmake_vars := $(qmake_vars) \
		DEFINES+="CMPLAYER_VLC_PLUGINS_PATH=\\\\\\\"$(CMPLAYER_VLC_PLUGINS_PATH)\\\\\\\"" #\
#		DEFINES+="CMPLAYER_SKIN_PATH=\\\\\\\"$(CMPLAYER_SKIN_PATH)\\\\\\\""
endif

all: vlc-plugins skin cmplayer
ifeq ($(os),osx)
	install -d $(cmplayer_exec_path)/lib
	install -d $(cmplayer_exec_path)/$(vlc_plugins_dir)
	$(install_file) $(VLC_LIB_PATH)/*.dylib* $(cmplayer_exec_path)/lib
	$(install_file) $(VLC_PLUGINS_PATH)/*.dylib $(cmplayer_exec_path)/$(vlc_plugins_dir)
	$(install_file) bin/$(vlc_plugins_dir)/*.dylib $(cmplayer_exec_path)/$(vlc_plugins_dir)
#	$(install_dir) bin/skin $(cmplayer_exec_path)/skin
	$(MACDEPLOYQT) bin/$(cmplayer_exec).app
endif

cmplayer: translations libchardet
	cd src/cmplayer && $(QMAKE) $(qmake_vars) cmplayer.pro 
	cd src/cmplayer && make

vlc-plugins: bin_dir
	cd src/$(vlc_plugins_dir) && make
	install -d bin/$(vlc_plugins_dir)
ifeq ($(os),osx)
	$(install_file) src/$(vlc_plugins_dir)/libcmplayer-*_plugin.dylib bin/$(vlc_plugins_dir)
else
	$(install_file) src/$(vlc_plugins_dir)/libcmplayer-*_plugin.so bin/$(vlc_plugins_dir)
endif

translations:
	cd src/cmplayer/translations && $(LRELEASE) cmplayer_ko.ts -qm cmplayer_ko.qm
	cd src/cmplayer/translations && $(LRELEASE) cmplayer_en.ts -qm cmplayer_en.qm
	cd src/cmplayer/translations && $(LRELEASE) cmplayer_ja.ts -qm cmplayer_ja.qm

libchardet:
ifneq ($(configured),configured)
	cd src/libchardet* && ./configure --enable-shared=no --enable-static=yes
	echo configured > configured
endif
	cd src/libchardet* && make

skin: bin_dir
#	$(install_dir) src/skin bin/skin

bin_dir:
	install -d bin

clean:
	-cd src/$(vlc_plugins_dir) && make clean
	-cd src/cmplayer && $(QMAKE) $(qmake_vars) cmplayer.pro && make clean
	-cd src/libchardet* && make distclean
	-rm -rf bin/*
	-rm configured
	
install: cmplayer
ifeq ($(os),linux)
	-install -d $(DEST_DIR)$(BIN_PATH)
	-install -d $(DEST_DIR)$(CMPLAYER_VLC_PLUGINS_PATH)
	-install -d $(DEST_DIR)$(APP_PATH)
	-install -d $(DEST_DIR)$(ACTION_PATH)
	-install -d $(DEST_DIR)$(ICON_PATH)/16x16/apps
	-install -d $(DEST_DIR)$(ICON_PATH)/22x22/apps
	-install -d $(DEST_DIR)$(ICON_PATH)/24x24/apps
	-install -d $(DEST_DIR)$(ICON_PATH)/32x32/apps
	-install -d $(DEST_DIR)$(ICON_PATH)/48x48/apps
	-install -d $(DEST_DIR)$(ICON_PATH)/64x64/apps
	-install -d $(DEST_DIR)$(ICON_PATH)/128x128/apps
	-install -d $(DEST_DIR)$(ICON_PATH)/256x256/apps
#	-install -d $(DEST_DIR)$(ICON_PATH)/scalable/apps
	$(install_exe) bin/$(cmplayer_exec) $(DEST_DIR)$(BIN_PATH)
	$(install_file) bin/$(vlc_plugins_dir)/libcmplayer*_plugin.so $(DEST_DIR)$(CMPLAYER_VLC_PLUGINS_PATH) 
	$(install_file) cmplayer.desktop $(DEST_DIR)$(APP_PATH)
	$(install_file) cmplayer-opendvd.desktop $(DEST_DIR)$(ACTION_PATH)
	$(install_file) icons/cmplayer16.png $(DEST_DIR)$(ICON_PATH)/16x16/apps/cmplayer.png
	$(install_file) icons/cmplayer22.png $(DEST_DIR)$(ICON_PATH)/22x22/apps/cmplayer.png
	$(install_file) icons/cmplayer24.png $(DEST_DIR)$(ICON_PATH)/24x24/apps/cmplayer.png
	$(install_file) icons/cmplayer32.png $(DEST_DIR)$(ICON_PATH)/32x32/apps/cmplayer.png
	$(install_file) icons/cmplayer48.png $(DEST_DIR)$(ICON_PATH)/48x48/apps/cmplayer.png
	$(install_file) icons/cmplayer64.png $(DEST_DIR)$(ICON_PATH)/64x64/apps/cmplayer.png
	$(install_file) icons/cmplayer128.png $(DEST_DIR)$(ICON_PATH)/128x128/apps/cmplayer.png
	$(install_file) icons/cmplayer256.png $(DEST_DIR)$(ICON_PATH)/256x256/apps/cmplayer.png
#	$(install_file) icons/cmplayer.svg $(DEST_DIR)$(ICON_PATH)/scalable/apps/cmplayer.svg
endif

uninstall:
ifeq ($(os),linux)
	-rm -f $(BIN_PATH)/cmplayer
	-rm -f $(CMPLAYER_VLC_PLUGINS_PATH)/libcmplayer*_plugin.so
	-rm -f $(APP_PATH)/cmplayer.desktop
	-rm -f $(ACTION_PATH)/cmplayer-opendvd.desktop
	-rm -f $(ICON_PATH)/16x16/apps/cmplayer.png
	-rm -f $(ICON_PATH)/22x22/apps/cmplayer.png
	-rm -f $(ICON_PATH)/24x24/apps/cmplayer.png
	-rm -f $(ICON_PATH)/32x32/apps/cmplayer.png
	-rm -f $(ICON_PATH)/48x48/apps/cmplayer.png
	-rm -f $(ICON_PATH)/64x64/apps/cmplayer.png
	-rm -f $(ICON_PATH)/128x128/apps/cmplayer.png
	-rm -f $(ICON_PATH)/256x256/apps/cmplayer.png
	-rmdir $(BIN_PATH)
	-rmdir $(CMPLAYER_VLC_PLUGINS_PATH)
	-rmdir $(APP_PATH)
	-rmdir $(ACTION_PATH)
	-rmdir $(ICON_PATH)/16x16/apps
	-rmdir $(ICON_PATH)/22x22/apps
	-rmdir $(ICON_PATH)/24x24/apps
	-rmdir $(ICON_PATH)/32x32/apps
	-rmdir $(ICON_PATH)/48x48/apps
	-rmdir $(ICON_PATH)/64x64/apps
	-rmdir $(ICON_PATH)/128x128/apps
	-rmdir $(ICON_PATH)/256x256/apps
endif
