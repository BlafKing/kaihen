# SPDX-License-Identifier: GPL-3.0-or-later
#
# ftpd classic for Switch 2, with the Switch 2 devkit. It compiles the sources
# and definitions of upstream's CMakeLists.txt for NINTENDO_SWITCH with
# FTPD_CLASSIC, against libounce instead of libnx, and links them with
# libounce's crt0, linker script and runtime, zlib from the devkitPro
# portlibs, and the Microsoft GSL 4.1.0 headers (the archive upstream's CMake
# fetches, MD5-checked as there).
#
# release/Makefile checks out upstream ftpd (mtheall/ftpd) at the commit that
# the Dockerfile names and runs this from the checkout's root:
#   make -f KAIHEN/release/ftpd.mk    ->  build/switch2/ftpd-classic.nro
DEVKITPRO ?= /opt/devkitpro
LIBOUNCE := $(DEVKITPRO)/libounce
# The Switch 2 CPU flags (SWITCH2_CPU).
include $(LIBOUNCE)/switch2_cpu.mk
TOOLS := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
OUT ?= build/switch2

NAME := ftpd-classic
VERSION := 3.2.2
AUTHOR := (c) 2026 Michael Theall, Dave Murphy, TuxSH

GSL := build/deps/GSL-4.1.0
GSL_URL := https://github.com/microsoft/GSL/archive/refs/tags/v4.1.0.tar.gz
GSL_MD5 := 7e6883a254e73a8b2368a0d26efe68a7

CXX_SOURCES := fs ftpConfig ftpServer ftpSession ioBuffer log main sockAddr \
    socket mdns switch/platform
# Switch startup, and the glob implementation that upstream adds for every
# target that is not UNIX.
C_SOURCES := switch/init posix/collate posix/collcmp posix/glob
# source/a/b.cpp -> $(OUT)/obj/a_b.o
object = $(OUT)/obj/$(subst /,_,$(1)).o
OBJECTS := $(foreach s,$(CXX_SOURCES) $(C_SOURCES),$(call object,$(s)))

ARCH := $(SWITCH2_CPU) -mtp=soft -fPIE
COMMON := $(ARCH) -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror \
    -D__SWITCH__ -D__SWITCH2__ -DCLASSIC -DNO_IPV6 \
    '-DSTATUS_STRING="ftpd v$(VERSION)"' '-DFTPDCONFIG="/config/ftpd/ftpd.cfg"' \
    -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 -DIMGUI_DISABLE_DEFAULT_SHELL_FUNCTIONS=1 \
    -Iinclude -isystem $(GSL)/include -isystem $(LIBOUNCE)/include \
    -isystem $(DEVKITPRO)/portlibs/switch/include
CXXFLAGS := -std=gnu++20 -fno-rtti -fno-exceptions $(COMMON)
CFLAGS := -std=gnu11 $(COMMON)

all: $(OUT)/$(NAME).nro

$(GSL)/include:
	mkdir -p build/deps
	curl -sSL -o build/deps/gsl.tar.gz $(GSL_URL)
	echo "$(GSL_MD5)  build/deps/gsl.tar.gz" | md5sum -c --quiet
	tar -xzf build/deps/gsl.tar.gz -C build/deps

define compile_cxx
$(call object,$(1)): source/$(1).cpp | $(GSL)/include
	@mkdir -p $$(dir $$@)
	$(TOOLS)g++ $(CXXFLAGS) -c $$< -o $$@
endef
define compile_c
$(call object,$(1)): source/$(1).c | $(GSL)/include
	@mkdir -p $$(dir $$@)
	$(TOOLS)gcc $(CFLAGS) -c $$< -o $$@
endef
$(foreach s,$(CXX_SOURCES),$(eval $(call compile_cxx,$(s))))
$(foreach s,$(C_SOURCES),$(eval $(call compile_c,$(s))))

# The objects link in name order.
$(OUT)/$(NAME).elf: $(OBJECTS)
	$(TOOLS)g++ -specs=$(LIBOUNCE)/switch.specs $(ARCH) -Wl,-Map,$(OUT)/$(NAME).map \
	    $(sort $(OBJECTS)) -L$(DEVKITPRO)/portlibs/switch/lib -L$(LIBOUNCE)/lib -lz -lnx -o $@

$(OUT)/$(NAME).nacp:
	@mkdir -p $(OUT)
	$(DEVKITPRO)/tools/bin/nacptool --create "ftpd classic" "$(AUTHOR)" "$(VERSION)" $@

$(OUT)/$(NAME).nro: $(OUT)/$(NAME).elf $(OUT)/$(NAME).nacp meta/ftpd.jpg
	$(DEVKITPRO)/tools/bin/elf2nro $< $@ --nacp=$(OUT)/$(NAME).nacp --icon=meta/ftpd.jpg

clean:
	rm -rf $(OUT)

.PHONY: all clean
