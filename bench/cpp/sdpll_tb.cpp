////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	sdpll_tb.cpp
// {{{
// Project:	A collection of phase locked loop (PLL) related projects
//
// Purpose:	
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2017-2021, Gisselquist Technology, LLC
// {{{
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	GPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
// }}}
#include <stdio.h>
#include <verilated.h>
#include "verilated_vcd_c.h"
#include "Vsdpll.h"
#include "Vsdpll___024root.h"

#ifdef	OLD_VERILATOR
// {{{
#define	VVAR(A)	v__DOT_ ## A
#error something
#else
#define	VVAR(A)	rootp->sdpll__DOT_ ## A
#endif
// }}}

#define	r_step	VVAR(_r_step)
#define	ctr	VVAR(_ctr)

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	Vsdpll		tb;
	FILE		*intfp;
	int	lclphase, lclstep;

	// Set up trace file generation
	// {{{
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb.trace(tfp, 99);
	tfp->open("sdpll.vcd");
	// }}}

	// Open an output file for DSP-type data
	// {{{
	intfp = fopen("sdpll.32t","w");
	assert(intfp);
	// }}}

	// Initialize our core
	// {{{
	tb.i_lgcoeff = 6;
	lclphase     = rand();
	lclstep      = 0x31415928;
	tb.i_step    = lclstep + (lclstep>>3);
	tb.i_ld      = 1;
	tb.i_clk     = 0;
	tb.i_ce      = 1;
	// }}}

	// Main simulation loop
	// {{{
	for(int k=0; k<65536; k++) {
		// Step the clock
		// {{{
		tb.eval();
		tfp->dump(10*k+8);
		tb.i_clk = 1;
		tb.eval();
		tfp->dump(10*k+10);
		tb.i_clk = 0;
		tb.eval();
		tfp->dump(10*k+15);
		// }}}

		// Record our key internal wires and results for later analysis
		// {{{
		{
			int	od[7];
			od[0] = lclphase;
			od[1] = tb.r_step;
			od[2] = tb.i_input;
			od[3] = tb.o_err;
			if (od[3] == 3)
				od[3] = -1;
			od[4] = tb.ctr;
			od[5] = tb.ctr - lclphase;
			od[6] = tb.o_dbg << (32-10);
			od[6]>>= (32-10);

			fwrite(od, sizeof(int), 7, intfp);
		}
		// }}}

		// Set the inputs for the next round
		// {{{
		tb.i_ld = 0;
		tb.i_clk = 0;
		lclphase += lclstep;
		tb.i_input = (lclphase >> 31)&1;
		// }}}
	}
	// }}}

	// Clean up and exit
	// {{{
	tfp->close();
	fclose(intfp);
	printf("Simulation complete\n");
	// }}}
}
