################################################################################
##
## Filename:	bench/cpp/Makefile
## {{{
## Project:	A collection of phase locked loop (PLL) related projects
##
## Purpose:	This file directs the build of a Verilator-based test bench to
##		prove that the various PLLs within this project work.  This
##	build must be called after building in rtl, since it depends upon the
##	products of that build.
##
## Targets:
##
##	all:	Builds all test benches
##
##	clean:	Cleans up all of the build products, together with any .vcd
##		files, so you can start over from scratch.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
## }}}
## Copyright (C) 2017-2020, Gisselquist Technology, LLC
## {{{
## This program is free software (firmware): you can redistribute it and/or
## modify it under the terms of the GNU General Public License as published
## by the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
## target there if the PDF file isn't present.)  If not, see
## <http://www.gnu.org/licenses/> for a copy.
##
## License:	GPL, v3, as defined and found on www.gnu.org,
##		http://www.gnu.org/licenses/gpl.html
##
################################################################################
##
##
# Make certain the "all" target is the first and therefore the default target
.PHONY: all
all:
# we'll fill in what "all" references in a moment
#
# Set up some variables
# }}}
all:
## {{{
CXX  := g++
OBJDIR:= obj-pc
RTLD := ../../rtl
ROBJD:= $(RTLD)/obj_dir
ifneq ($(VERILATOR_ROOT),)
VERILATOR:=$(VERILATOR_ROOT)/bin/verilator
else
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
endif
export  $(VERILATOR)
VROOT  := $(VERILATOR_ROOT)
VDEFS  := $(shell ./vversion.sh)
VINCD  := $(VROOT)/include
INCS   := -I$(VINCD) -I$(ROBJD)
# VSRCS:= $(VROOT)/include/verilated.cpp $(VROOT)/include/verilated_vcd_c.cpp
VSRCS  := verilated.cpp verilated_vcd_c.cpp
VOBJS  := $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(VSRCS)))
SDOBJ  := $(ROBJD)/Vsdpll__ALL.a
STBOBJ :=$(ROBJD)/Vstbpll__ALL.a
QDOBJ  := $(ROBJD)/Vquadpll__ALL.a
CRDCOBJ:= $(ROBJD)/Vdblcordicpll__ALL.a
SUBMAKE := $(MAKE) --no-print-directory -C
CFLAGS   := -Og -g -Wall $(INCS) $(VDEFS)

SOURCES := sdpll_tb.cpp stbpll_tb.cpp quadpll_tb.cpp
HEADERS := $(foreach header,$(subst  .cpp,.h,$(SOURCES)),$(wildcard $(header)))
OBJECTS := $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(SOURCES))) $(VOBJS)
#
# }}}
PROGRAMS := sdpll_tb stbpll_tb quadpll_tb dblcordicpll_tb
#
# Now the return to the default/"all" target, and fill in some details
all: $(PROGRAMS)

#
# Generic build instructions for object files
# {{{
$(OBJDIR)/%.o: %.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) -c $< -o $@

#
# And we'll repeat those instructions for building object files from sources
# within the Verilator directory found within $(VERILATOR_ROOT)
$(OBJDIR)/%.o: $(VINCD)/%.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) -c $< -o $@
## }}}
#
# sdpll_tb
## {{{
SDOBJS  := $(OBJDIR)/sdpll_tb.o $(VOBJS) $(SDOBJ)
sdpll_tb: $(SDOBJS)
	$(CXX) $(INCS) $(SDOBJS) -o $@
## }}}
# stdpll_tb
## {{{
STBOBJS := $(OBJDIR)/stbpll_tb.o $(VOBJS) $(STBOBJ)
stbpll_tb: $(STBOBJS)
	$(CXX) $(INCS) $(STBOBJS) -o $@
## }}}
# quadpll_tb
## {{{
QUADOBJS := $(OBJDIR)/quadpll_tb.o $(VOBJS) $(QDOBJ)
quadpll_tb: $(QUADOBJS)
	$(CXX) $(INCS) $(QUADOBJS) -o $@
## }}}
# dblcordicpll_tb
## {{{
CORDICOBJS := $(OBJDIR)/dblcordicpll_tb.o $(VOBJS) $(CRDCOBJ)
dblcordicpll_tb: $(CORDICOBJS)
	$(CXX) $(INCS) $(CORDICOBJS) -o $@
## }}}

#
#
# The "test" target, just runs our test bench object
#
.PHONY: test
## {{{
test:	sdpll.vcd stbpll.vcd quadpll.vcd dblcordicpll.vcd

sdpll.vcd: sdpll_tb
	./sdpll_tb

stbpll.vcd: stbpll_tb
	./stbpll_tb

quadpll.vcd: quadpll_tb
	./quadpll_tb

dblcordicpll.vcd: dblcordicpll_tb
	./dblcordicpll_tb
## }}}

#
.PHONY: clean
## {{{
#
# The "clean" target, removing any and all remaining build (and test) products
#
clean:
	rm -f *.vcd
	rm -f $(PROGRAMS)
	rm -rf $(OBJDIR)/
## }}}

#
.PHONY: depends
## {{{

# The "depends" target, to know what files things depend upon.  The depends
# file itself is kept in $(OBJDIR)/depends.txt
#
define build-depends
	$(mk-objdir)
	@echo "Building dependency file"
	@$(CXX) $(CFLAGS) $(INCS) -MM $(SOURCES) > $(OBJDIR)/xdepends.txt
	@sed -e 's/^.*.o: /$(OBJDIR)\/&/' < $(OBJDIR)/xdepends.txt > $(OBJDIR)/depends.txt
	@rm $(OBJDIR)/xdepends.txt
endef

depends: tags
	$(build-depends)

$(OBJDIR)/depends.txt: depends
## }}}

#
# Make sure the $(OBJDIR)/ directory exists.  This has taken some work to get
## {{{
# right.  While "mkdir -p $(OBJDIR)" could be used to do this as well, it
# always bothered me that it seemed to be perpetually running.  Hence, we'll
# first check if the directory exists, and only create it if it does not.
# Finally, by adding the @ in front of the bash command, it won't get printed
# to the screen.  That way ... I can run it as often as I want without getting
# annoyed by it.  ;)
define	mk-objdir
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR); fi"
endef
## }}}

.PHONY: tags
## {{{
#
# The "tags" target
#
tags:	$(SOURCES) $(HEADERS)
	@echo "Generating tags"
	@ctags $(SOURCES) $(HEADERS)
## }}}

#
# Include our generated dependency file.  The "-" in front of the include
# basically tells "make" to include it if it can, and ignore it if it cannot
# be included (i.e. if it doesn't exist)
ifneq ($(MAKECMDGOALS),clean)
-include $(OBJDIR)/depends.txt
endif
