################################################################################
##
## Filename:	rtl/Makefile
## {{{
## Project:	A collection of phase locked loop (PLL) related projects
##
## Purpose:	To direct the Verilator build of the SoC sources.  The result
##		is C++ code (built by Verilator), that is then built (herein)
##	into a library.
##
## Targets:	The default target, all, builds the target test, which includes
##		the libraries necessary for Verilator testing.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
## }}}
## Copyright (C) 2017-2024, Gisselquist Technology, LLC
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
## }}}
all:	test
YYMMDD=`date +%Y%m%d`
CXX   := g++
FBDIR := .
VDIRFB:= $(FBDIR)/obj_dir
VERILATOR := verilator
VFLAGS:= -trace -Wall -MMD -cc
## }}}
.PHONY: test sdpll stbpll quadpll dblcordicpll
test: sdpll stbpll quadpll dblcordicpll
## {{{
sdpll:  $(VDIRFB)/Vsdpll__ALL.a
stbpll: $(VDIRFB)/Vstbpll__ALL.a
quadpll: $(VDIRFB)/Vquadpll__ALL.a
dblcordicpll: $(VDIRFB)/Vdblcordicpll__ALL.a

$(VDIRFB)/Vsdpll__ALL.a: $(VDIRFB)/Vsdpll.h $(VDIRFB)/Vsdpll.cpp
$(VDIRFB)/Vsdpll__ALL.a: $(VDIRFB)/Vsdpll.mk
$(VDIRFB)/Vsdpll.h $(VDIRFB)/Vsdpll.cpp $(VDIRFB)/Vsdpll.mk: sdpll.v

$(VDIRFB)/Vstbpll__ALL.a: $(VDIRFB)/Vstbpll.h $(VDIRFB)/Vstbpll.cpp
$(VDIRFB)/Vstbpll__ALL.a: $(VDIRFB)/Vstbpll.mk
$(VDIRFB)/Vstbpll.h $(VDIRFB)/Vstbpll.cpp $(VDIRFB)/Vstbpll.mk: stbpll.v

$(VDIRFB)/Vquadpll__ALL.a: $(VDIRFB)/Vquadpll.h $(VDIRFB)/Vquadpll.cpp
$(VDIRFB)/Vquadpll__ALL.a: $(VDIRFB)/Vquadpll.mk
$(VDIRFB)/Vquadpll.h $(VDIRFB)/Vquadpll.cpp $(VDIRFB)/Vquadpll.mk: quadpll.v

$(VDIRFB)/Vdblcordicpll__ALL.a: $(VDIRFB)/Vdblcordicpll.h $(VDIRFB)/Vdblcordicpll.cpp
$(VDIRFB)/Vdblcordicpll__ALL.a: $(VDIRFB)/Vdblcordicpll.mk
$(VDIRFB)/Vdblcordicpll.h $(VDIRFB)/Vdblcordicpll.cpp $(VDIRFB)/Vdblcordicpll.mk: dblcordicpll.v seqcordic.v seqpolar.v

$(VDIRFB)/V%.cpp $(VDIRFB)/V%.h $(VDIRFB)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

$(VDIRFB)/V%__ALL.a: $(VDIRFB)/V%.mk
	cd $(VDIRFB); make -f V$*.mk

.PHONY: clean
clean:
	rm -rf $(VDIRFB)/*.mk
	rm -rf $(VDIRFB)/*.cpp
	rm -rf $(VDIRFB)/*.h
	rm -rf $(VDIRFB)/
