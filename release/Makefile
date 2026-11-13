# SPDX-License-Identifier: ISC
#
# Builds the kaiHEN release zip:
#   bootstrap.bin, hbmenu.nro, ro/main, hen/main,
#   game/main                    nx-hbloader
#   programs/ftpd-classic.nro    ftpd classic
#
# The Dockerfile runs this with RELEASE=1 and sets the sources and commits:
#   make -f release/Makefile RELEASE_ZIP=FILE \
#       HBLOADER_URL=... HBLOADER_COMMIT=... HBMENU_URL=... HBMENU_COMMIT=... \
#       FTPD_URL=... FTPD_COMMIT=...
DEVKITPRO ?= /opt/devkitpro
RELEASE_ZIP ?= build/kaiHEN.zip
DEPS := build/release
HBLOADER := $(DEPS)/nx-hbloader
HBMENU := $(DEPS)/nx-hbmenu
FTPD := $(DEPS)/ftpd
STAGE := $(DEPS)/zip

# Checks out one commit of a repository into a folder.
#   $(call checkout,DIR,URL,COMMIT)
define checkout
rm -rf $(1)
git init -q $(1)
git -C $(1) fetch -q --depth=1 $(2) $(3)
git -C $(1) checkout -q FETCH_HEAD
endef

all: $(RELEASE_ZIP)

kaihen:
	$(MAKE) -f Makefile

$(HBLOADER)/build/clean/main:
	$(call checkout,$(HBLOADER),$(HBLOADER_URL),$(HBLOADER_COMMIT))
	$(MAKE) -C $(HBLOADER)/switch2 -f Makefile.clean \
	    KAIHEN_INCLUDE=$(CURDIR)/libkaihen/include

$(HBMENU)/build/nro/nro/hbmenu.nro:
	$(call checkout,$(HBMENU),$(HBMENU_URL),$(HBMENU_COMMIT))
	$(MAKE) -C $(HBMENU) -f switch2/Makefile

$(FTPD)/build/switch2/ftpd-classic.nro:
	$(call checkout,$(FTPD),$(FTPD_URL),$(FTPD_COMMIT))
	$(MAKE) -C $(FTPD) -f $(CURDIR)/release/ftpd.mk

$(RELEASE_ZIP): kaihen $(HBLOADER)/build/clean/main \
        $(HBMENU)/build/nro/nro/hbmenu.nro $(FTPD)/build/switch2/ftpd-classic.nro
	rm -rf $(STAGE)
	mkdir -p $(STAGE)/ro $(STAGE)/hen $(STAGE)/game $(STAGE)/programs
	cp bootstrap/build/bootstrap.bin $(STAGE)/bootstrap.bin
	cp $(HBMENU)/build/nro/nro/hbmenu.nro $(STAGE)/hbmenu.nro
	cp ro/build/main $(STAGE)/ro/main
	cp hen/build/main $(STAGE)/hen/main
	cp $(HBLOADER)/build/clean/main $(STAGE)/game/main
	cp $(FTPD)/build/switch2/ftpd-classic.nro $(STAGE)/programs/
	mkdir -p $(dir $(abspath $@))
	rm -f $@
	cd $(STAGE) && zip -q -r -X $(abspath $@) .

.PHONY: all kaihen
