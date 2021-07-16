////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	quadpll.v
// {{{
// Project:	A collection of phase locked loop (PLL) related projects
//
// Purpose:	This is a basic, 1-clock quadrature DPLL.  It doesn't use an
//		arctan for a phase detector, but rather plain old logic.  It
//	doesn't use a sinewave table for the NCO, neither does it use a CORDIC.
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
// }}}
// License:	GPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/gpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
// }}}
module	quadpll #(
		// {{{
		parameter			PHASE_BITS = 32,
		parameter	[0:0]		OPT_TRACK_FREQUENCY = 1'b1,
		parameter [PHASE_BITS-1:0]	INITIAL_PHASE_STEP = 0,
		parameter	[0:0]	OPT_GLITCHLESS = 1'b1,
		localparam			MSB=PHASE_BITS-1
		// }}}
	) (
		// {{{
		input	wire			i_clk,
		//
		input	wire			i_ld,
		input	wire	[(MSB-1):0]	i_step,
		//
		input	wire			i_ce,
		input	wire	[1:0]		i_input,	// 1 = I, 0 = Q
		input	wire	[4:0]		i_lgcoeff,
		output	wire	[PHASE_BITS-1:0] o_phase,
		output	reg	[1:0]		o_err,
		output	reg			o_locked
		//
`ifdef	VERILATOR
		, output wire	[13:0]		o_dbg
`endif
		// }}}
	);

	// Signal declarations
	// {{{
	reg		lead;	// lag
	reg		phase_err;
	reg	[MSB:0]	ctr, phase_correction, freq_correction, r_step;
	// }}}

	// lead, phase_err
	// {{{
	// Lead is true if the counter changes before the input
	// changes, false otherwise
	//

	// Any disagreement between the high order counter bit and the input
	// is a phase error that we will need to correct
	//
	// Input {I,Q} (i.e. X,Y) will rotate: 00, 10, 11, 01
	// The counter will rotate: 00, 01, 10, 11
	//
	always @(*)
	case({ i_input, ctr[MSB:MSB-1] })
	//
	4'b0000: { lead, phase_err } = 2'b00;	// No err
	4'b0001: { lead, phase_err } = 2'b11;
	4'b0010: { lead, phase_err } = 2'b11;
	4'b0011: { lead, phase_err } = 2'b01;
	//
	4'b1000: { lead, phase_err } = 2'b01;
	4'b1001: { lead, phase_err } = 2'b00;	// No Err
	4'b1010: { lead, phase_err } = 2'b11;
	4'b1011: { lead, phase_err } = 2'b01;
	//
	4'b1100: { lead, phase_err } = 2'b11;
	4'b1101: { lead, phase_err } = 2'b01;
	4'b1110: { lead, phase_err } = 2'b00;	// No err
	4'b1111: { lead, phase_err } = 2'b11;
	//
	4'b0100: { lead, phase_err } = 2'b11;
	4'b0101: { lead, phase_err } = 2'b01;
	4'b0110: { lead, phase_err } = 2'b01;
	4'b0111: { lead, phase_err } = 2'b00;	// No err
	endcase
	// }}}

	// o_locked
	// {{{
	// A crude lock indicator.  If we are ever off by 180 degrees, then we
	// clearly aren't locked.  It's crude, because anything between about
	// -135 and 135 will still appear to be locked, and because the lock
	// indicator will almost always glitch--but it should be enough to see
	// it on a trace.
	always @(posedge i_clk)
	if (i_ce)
	begin
		case({ i_input, ctr[MSB:MSB-1] })
		//
		4'b0010: o_locked <= 1'b0;
		4'b1011: o_locked <= 1'b0;
		4'b1100: o_locked <= 1'b0;
		4'b0101: o_locked <= 1'b0;
		default: o_locked <= 1'b1;	// Everything else
		endcase
	end
	// }}}

	// phase_correction
	// {{{
	// How much we correct our phase by is a function of our loop
	// coefficient, here represented by 2^{-i_lgcoeff}.
	initial	phase_correction = 0;
	always @(posedge i_clk)
		phase_correction <= {1'b1,{(MSB){1'b0}}} >> i_lgcoeff;
	// }}}

	// ctr
	// {{{
	// Finally, apply a correction
	initial	ctr = 0;
	always @(posedge i_clk)
	if (i_ce)
	begin
		// If we match, then just step the counter forward
		// by one delta phase amount
		if (!phase_err)
			ctr <= ctr + r_step;

		// Otherwise we don't match.  We need to adjust our
		// counter based upon how far off we are.
		// If the counter is ahead of the input, then we should
		// slow it down a touch.
		else if (lead)
		begin
			// This check is necessary to keep us glitch-free
			// If the step is less than the phase correction, the
			// recovered clock might appear to go backwards.
			if (!OPT_GLITCHLESS || r_step > phase_correction)
				ctr <= ctr + r_step - phase_correction;
		end

		// Likewise, if the counter is falling behind the input,
		// then we need to speed it up.
		else // if (lag)
			ctr <= ctr + r_step + phase_correction;
	end
	// }}}

	// o_phase (== ctr)
	// {{{
	// Incidentally, we'll also output this internal phase in case you wish
	// to use it for synchronizing anything with this clock.
	assign	o_phase = ctr;
	// }}}

	// freq_correction
	// {{{
	// The frequency correction needs to be the phase_correction squared
	// divided by four in order to get a critically damped loop
	initial	freq_correction = 0;
	always @(posedge i_clk)
		freq_correction <= { 3'b001, {(MSB-2){1'b0}} } >> (2*i_lgcoeff);
	// }}}

	// r_step
	// {{{
	// On the clock, we'll apply this frequency correction, either slowing
	// down or speeding up the frequency, any time there is a phase error.
	// The exceptions are if 1) we aren't tracking frequency, or 2) the
	// user wants to load in what frequency to use.
	initial	r_step = INITIAL_PHASE_STEP;
	always @(posedge i_clk)
	if (i_ld)
		r_step <= { 1'b0, i_step };
	else if ((i_ce)&&(OPT_TRACK_FREQUENCY)&&(phase_err))
	begin
		if (lead)
			r_step <= r_step - freq_correction;
		else
			r_step <= r_step + freq_correction;
	end
	// }}}

	// o_err
	// {{{
	// Output an error signal as follows:
	// 1. If the two signals match, both one or both zeros, then there is
	//	no phase error.
	// 2. If there is a mismatch and ...
	//	A. Our counter leads our input, then our error is -1, else if
	//	B. Our input leads our counter (!lead), then our error signal
	//		is a +1.
	// All three of these numbers, -1, 0, and 1, all fit within two bits,
	// so that's what we'll use here..
	initial	o_err = 2'h0;
	always @(posedge i_clk)
	if (i_ce)
		o_err <= (!phase_err) ? 2'b00 : ((lead) ? 2'b11 : 2'b01);
	// }}}

	// o_dbg -- a filtered o_err measurement
	// {{{
	// The error signal by itself can be ... misleading.  Whenever it takes
	// place, it is always a maximum error.  The signal is better understood
	// by how many error signals take place over time.  To get this
	// information, let's run it through a boxcar filter.
`ifdef	VERILATOR
	boxcar #(.IW(2), .LGMEM(12))
		bcar(i_clk, 1'b0, 12'heff, i_ce, o_err, o_dbg);
`endif
	// }}}
endmodule
