////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	dblcordicpll_tb.cpp
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
// Copyright (C) 2020-2021, Gisselquist Technology, LLC
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
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
// }}}
#include <stdio.h>
#include <verilated.h>
#include <math.h>
#include "verilated_vcd_c.h"
#include "Vdblcordicpll.h"
#include "Vdblcordicpll___024root.h"

#ifdef	OLD_VERILATOR
// {{{
#define	VVAR(A)	v__DOT_ ## A
#error something
#else
#define	VVAR(A)	rootp->dblcordicpll__DOT_ ## A
#endif
// }}}

#define	r_step	VVAR(_r_step)
#define	ctr	VVAR(_r_phase)

int	main(int argc, char **argv) {
	// {{{
	Verilated::commandArgs(argc, argv);
	Vdblcordicpll	tb;
	FILE		*intfp;
	int	lclphase, lclstep;

	// Open a trace file
	// {{{
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb.trace(tfp, 99);
	tfp->open("dblcordicpll.vcd");
	// }}}

	// Open an output file for Octave analysis
	// {{{
	intfp = fopen("dblcordicpll.32t","w");
	assert(intfp);
	// }}}

	// Initialize our core
	// {{{
	tb.i_lgcoeff = 5;
	lclphase     = rand();
	lclstep      = 0x31415928 >> 2;
	// lclstep      = 0x03141593;
	tb.i_step    = lclstep + (lclstep>>4);
	tb.i_input   = 0;
	tb.i_ld      = 1;
	tb.i_clk     = 0;
	tb.i_ce      = 1;
	// }}}

	// Main simulation loop -- Run a test for 65536 clock cycles
	// {{{
	int	now = 0;
	for(int k=0; k<65536; k++) {
		// {{{
		double	sv;
		int	isv;

		tb.i_ce = 1;
		for(int ck=0; ck<19+29+4; ck++) {
			// Clock the data in and run the test
			// {{{
			tb.eval();
			tfp->dump(10*now+8);
			tb.i_clk = 1;
			tb.eval();
			tfp->dump(10*now+10);
			tb.i_clk = 0;
			tb.eval();
			tfp->dump(10*now+15);
			tb.i_ce = 0;
			now++;
			// }}}
		}

		// Dump the output
		// {{{
		{
			int	od[7];
			od[0] = lclphase;
			od[1] = tb.r_step;
			od[2] = tb.i_input;
			if (od[2] & 0x8000)
				od[2] = od[2] + 0xffff0000;
			od[3] = tb.o_err;
			if (od[3] == 3)
				od[3] = -1;
			od[4] = tb.ctr;
			od[5] = tb.ctr - lclphase;
			od[6] = 0;
			// od[6] = tb.o_dbg << (32-10);
			// od[6]>>= (32-10);

			fwrite(od, sizeof(int), 7, intfp);
		}
		// }}}

		// Setup inputs for the next round
		// {{{
		tb.i_ld = 0;
		tb.i_clk = 0;
		lclphase += lclstep;
		// sv = 8.0 * 2.0 * M_PI / ((double)0x10000000) * (double)lclphase;
		sv = ((unsigned)lclphase) / (double)(1 << 30);
		sv = 2.0 * M_PI * sv;
		sv = sin(sv) * 16384.0 / 2.0;
		isv = (int)sv;
		isv = isv & 0x0ffff;
		tb.i_input = isv;
		// }}}
		// }}}
	}
	// }}}

	tfp->close();
	fclose(intfp);
	// }}}
	printf("Simulation complete\n");
}
