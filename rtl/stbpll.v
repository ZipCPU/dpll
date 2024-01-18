////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	stbpll.v
// {{{
// Project:	A collection of phase locked loop (PLL) related projects
//
// Purpose:	A strobe PLL.  Given a strobe input, match a strobe output
//		and counter to that input.  Useful when needing to resample
//	from one channel to another.  In that case, the strobe signal is the
//	global CE signal from the incoming channel, and the outgoing phase
//	tells you where you are between samples at all times.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2018-2024, Gisselquist Technology, LLC
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
module	stbpll #(
		// {{{
		parameter		PHASE_BITS = 32,
		parameter	[0:0]	OPT_TRACK_FREQUENCY = 1'b1,
		parameter	[PHASE_BITS-1:0]	INITIAL_PHASE_STEP = 0,
		parameter	[0:0]	OPT_GLITCHLESS = 1'b1,
		localparam		MSB=PHASE_BITS-1
		// }}}
	) (
		// {{{
		input	wire			i_clk,
		//
		input	wire			i_ld,
		input	wire	[(MSB-1):0]	i_step,
		//
		input	wire			i_ce,
		input	wire			i_stb,
		input	wire	[4:0]		i_lgcoeff,
		output	reg			 o_stb,
		output	wire	[PHASE_BITS-1:0] o_phase
		//
`ifdef	VERILATOR
		, output reg	[1:0]		o_err,
		output	wire	[13:0]		o_dbg
`endif
		// }}}
	);

	// Signal declarations
	// {{{
	reg		lead;
	wire		w_lead;
	reg	[MSB:0]	ctr, phase_correction, freq_correction, r_step;
	wire		phase_err;
	reg		r_phase_err;
	// }}}

	////////////////////////////////////////////////////////////////////////
	//
	// Phase error, true or false
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	// True if our phase is in error, false otherwise.  If the loop is
	// in lock, this should only be true "between" strobes during an
	// error, as the two strobes are to be drawn together.
	//
	//

	always @(posedge i_clk)
	if (i_ce)
	begin
		if (!r_phase_err)
			r_phase_err <= (i_stb != o_stb);
		else if (lead)
		begin
			if (i_stb)
				r_phase_err <= 1'b0;
		end else // if (!lead)
		begin
			if (o_stb)
				r_phase_err <= 1'b0;
		end
	end

	assign	phase_err = r_phase_err;
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Lead: the direction of the phase error
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	// Lead is true if the our outgoing strobe takes place before the
	// incoming strobe, false otherwise.  Hence lead is true if we
	// are leading the input and need to slow down, false if we are
	// falling behind the input and need to speed up.  The value is
	// irrelevant if there is no error.
	//
	//
	assign	w_lead = ((o_stb)&&(!r_phase_err))
				||((lead)&&((!i_stb)||(r_phase_err)));

	always @(posedge i_clk)
	if (i_ce)
		lead <= w_lead;
	// }}}

	// phase_correction
	// {{{
	// How much we correct our phase by is a function of our loop
	// coefficient, here represented by 2^{-i_lgcoeff}.
	initial	phase_correction = 0;
	always @(posedge i_clk)
		phase_correction <= {1'b1, {(MSB){1'b0}} } >> i_lgcoeff;
	// }}}

	// ctr, o_phase
	// {{{
	// Finally, apply a correction
	initial	ctr = 0;
	always @(posedge i_clk)
	if (i_ce)
	begin
		// If we match, then just step the counter forward
		// by one delta phase amount
		if (!phase_err)
			{ o_stb,ctr } <= ctr + r_step;

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
				{ o_stb,ctr } <= ctr + r_step - phase_correction;
		end

		// Likewise, if the counter is falling behind the input,
		// then we need to speed it up.
		else // if (lag)
			{ o_stb,ctr } <= ctr + r_step + phase_correction;
	end

	// We'll also output this internal phase in case you wish
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

	// r_step -- frequency tracking
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

	// o_dbg
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
