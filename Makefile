# Makefile to create all versions of the Twitter Color Emoji SVGinOT font
# Run with: make -j [NUMBER_OF_CPUS]

# Use Linux Shared Memory to avoid wasted disk writes. Use /tmp to disable.
TMP := /dev/shm
#TMP := /tmp

# Where to find scfbuild?
SCFBUILD := SCFBuild/bin/scfbuild

VERSION := 0.1.0
FONT_PREFIX := BlobColorFont-SVG
REGULAR_FONT := build/$(FONT_PREFIX).ttf
REGULAR_PACKAGE := build/$(FONT_PREFIX)-$(VERSION)
MACOS_FONT := build/$(FONT_PREFIX)-macOS.ttf
MACOS_PACKAGE := build/$(FONT_PREFIX)-macOS-$(VERSION)
LINUX_PACKAGE := $(FONT_PREFIX)-Linux-$(VERSION)
DEB_PACKAGE := blobcolorfont
WINDOWS_TOOLS := windows
WINDOWS_PACKAGE := build/$(FONT_PREFIX)-Win-$(VERSION)

# There are two SVG source directories to keep the assets separate
# from the additions
SVG_BLOB := BlobStorage/svgs/all
# Will be used later
SVG_TWEMOJI := assets/twemoji-svg-empty

# Create the lists of traced and color SVGs
SVG_FILES := $(wildcard $(SVG_BLOB)/*.svg) $(wildcard $(SVG_TWEMOJI)/*.svg)
SVG_STAGE_FILES := $(patsubst $(SVG_BLOB)/%.svg, build/stage/%.svg, $(SVG_FILES))
SVG_STAGE_FILES := $(patsubst $(SVG_TWEMOJI)/%.svg, build/stage/%.svg, $(SVG_STAGE_FILES))
SVG_BW_FILES := $(patsubst build/stage/%.svg, build/svg-bw/%.svg, $(SVG_STAGE_FILES))
SVG_COLOR_FILES := $(patsubst build/stage/%.svg, build/svg-color/%.svg, $(SVG_STAGE_FILES))

.PHONY: all package regular-package linux-package macos-package windows-package copy-extra clean

all: $(REGULAR_FONT) $(MACOS_FONT)

# Create the operating system specific packages
package: regular-package linux-package deb-package macos-package windows-package

regular-package: $(REGULAR_FONT)
	rm -f $(REGULAR_PACKAGE).zip
	rm -rf $(REGULAR_PACKAGE)
	mkdir $(REGULAR_PACKAGE)
	cp $(REGULAR_FONT) $(REGULAR_PACKAGE)
	cp LICENSE* $(REGULAR_PACKAGE)
	cp README.md $(REGULAR_PACKAGE)
	7z a -tzip -mx=9 $(REGULAR_PACKAGE).zip ./$(REGULAR_PACKAGE)

linux-package: $(REGULAR_FONT)
	rm -f build/$(LINUX_PACKAGE).tar.gz
	rm -rf build/$(LINUX_PACKAGE)
	mkdir build/$(LINUX_PACKAGE)
	cp $(REGULAR_FONT) build/$(LINUX_PACKAGE)
	cp LICENSE* build/$(LINUX_PACKAGE)
	cp README.md build/$(LINUX_PACKAGE)
	cp -R linux/* build/$(LINUX_PACKAGE)
	tar zcvf build/$(LINUX_PACKAGE).tar.gz -C build $(LINUX_PACKAGE)

deb-package: linux-package
	rm -rf build/$(DEB_PACKAGE)-$(VERSION)
	cp build/$(LINUX_PACKAGE).tar.gz build/$(DEB_PACKAGE)_$(VERSION).orig.tar.gz
	cp -R build/$(LINUX_PACKAGE) build/$(DEB_PACKAGE)-$(VERSION)
	cd build/$(DEB_PACKAGE)-$(VERSION); debuild -us -uc
	#debuild -S
	#dput ppa:eosrei/fonts $(DEB_PACKAGE)_$(VERSION).changes

macos-package: $(MACOS_FONT)
	rm -f $(MACOS_PACKAGE).zip
	rm -rf $(MACOS_PACKAGE)
	mkdir $(MACOS_PACKAGE)
	cp $(MACOS_FONT) $(MACOS_PACKAGE)
	cp LICENSE* $(MACOS_PACKAGE)
	cp README.md $(MACOS_PACKAGE)
	7z a -tzip -mx=9 $(MACOS_PACKAGE).zip ./$(MACOS_PACKAGE)

windows-package: $(REGULAR_FONT)
	rm -f $(WINDOWS_PACKAGE).zip
	rm -rf $(WINDOWS_PACKAGE)
	mkdir $(WINDOWS_PACKAGE)
	cp $(REGULAR_FONT) $(WINDOWS_PACKAGE)
	cp LICENSE* $(WINDOWS_PACKAGE)
	cp README.md $(WINDOWS_PACKAGE)
	cp $(WINDOWS_TOOLS)/* $(WINDOWS_PACKAGE)
	7z a -tzip -mx=9 $(WINDOWS_PACKAGE).zip ./$(WINDOWS_PACKAGE)

# Build both versions of the fonts
$(REGULAR_FONT): $(SVG_BW_FILES) $(SVG_COLOR_FILES)
	$(SCFBUILD) -c scfbuild.yml -o $(REGULAR_FONT) --font-version="$(VERSION)"

$(MACOS_FONT): $(SVG_BW_FILES) $(SVG_COLOR_FILES)
	$(SCFBUILD) -c scfbuild-macos.yml -o $(MACOS_FONT) --font-version="$(VERSION)"

# Create black SVG traces of the color SVGs to use as glyphs.
# 1. Make the SVG into a PNG with Inkscape
# 2. Make the PNG into a BMP with ImageMagick and add margin by increasing the
#    canvas size to allow the outer "stroke" to fit.
# 3. Make the BMP into a Edge Detected PGM with mkbitmap
# 4. Make the PGM into a black SVG trace with potrace
build/svg-bw/%.svg: build/staging/%.svg | build/svg-bw
	inkscape -w 1000 -h 1000 -z -e $(TMP)/$(*F).png $<
	convert $(TMP)/$(*F).png -gravity center -extent 1066x1066 $(TMP)/$(*F).bmp
	rm $(TMP)/$(*F).png
	mkbitmap -g -s 1 -f 10 -o $(TMP)/$(*F).pgm $(TMP)/$(*F).bmp
	rm $(TMP)/$(*F).bmp
	potrace --flat -s --height 2048pt --width 2048pt -o $@ $(TMP)/$(*F).pgm
	rm $(TMP)/$(*F).pgm

# Optimize/clean the color SVG files
build/svg-color/%.svg: build/staging/%.svg | build/svg-color
	svgo -i $< -o $@

# Copy the files from multiple directories into one source directory
build/staging/%.svg: $(SVG_BLOB)/%.svg | build/staging
	cp $< $@

build/staging/%.svg: $(SVG_MORE)/%.svg | build/staging
	cp $< $@

# Create the build directories
build:
	mkdir build

build/staging: | build
	mkdir build/staging

build/svg-bw: | build
	mkdir build/svg-bw

build/svg-color: | build
	mkdir build/svg-color

clean:
	rm -rf build
