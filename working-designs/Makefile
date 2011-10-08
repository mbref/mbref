#
# Makefile to build and/or clean FPGA design projects
#
# Copyright (C) 2011 Stephan Linz <linz@li-pro.net>
#

XLBASE		:= /opt/Xilinx
XLENVSCR	:= settings32.sh


MAKESCRIPTS	:= $(wildcard */makescr)
PROJECTS	:= $(notdir $(patsubst %/,%,$(dir $(MAKESCRIPTS))))

define get_isevers
$(notdir $(subst -,/,$(1)))
endef

define get_padding
$(if $(findstring 12,$(1)),/ISE_DS,)
endef

define get_xlenvscr
$(XLBASE)/$(call get_isevers,$(1))$(call get_padding,$(1))/$(XLENVSCR)
endef

define gen_2xlenvscr
$(eval 2XLENVSCR_$(1) := $(call get_xlenvscr,$(1)))
endef

$(foreach proj,$(PROJECTS),$(call gen_2xlenvscr,$(proj)))

STATEDIR	:= gstate

all: $(foreach proj,$(PROJECTS),$(STATEDIR)/$(proj).build)

$(STATEDIR)/%.build: | mkdirs
	@echo
	@echo "building $(*) with" $(2XLENVSCR_$(*))
	@echo
	@pushd $(*) && \
	  ./makescr $(2XLENVSCR_$(*)) init_bram && \
	  ./makescr $(2XLENVSCR_$(*)) exporttosdk && \
	  ./makescr $(2XLENVSCR_$(*)) exporttoptx && \
	  ./makescr $(2XLENVSCR_$(*)) bit2bin && \
	  popd

clean: $(foreach proj,$(PROJECTS),$(STATEDIR)/$(proj).clean)
	@rm -rf $(STATEDIR)

$(STATEDIR)/%.clean:
	@echo
	@echo "cleanup $(*) with" $(2XLENVSCR_$(*))
	@echo
	@pushd $(*) && \
	  ./makescr $(2XLENVSCR_$(*)) clean && \
	  rm -f download.bin && \
	  popd

mkdirs:
	@mkdir -p $(STATEDIR)

print-%:
	@echo "$* is \"$($(*))\""

help: print-XLBASE print-XLENVSCR
	@echo "Available projects:"
	@for i in $(PROJECTS); do echo $$i; done;
