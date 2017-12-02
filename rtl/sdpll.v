////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	
//
// Project:	A collection of phase locked loop (PLL) related projects
//
// Purpose:	This is simplest, 1-clock DPLL that I can think of building
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Gisselquist Technology, LLC
//
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
//
`default_nettype	none
//
module	sdpll(i_clk, i_ld, i_step, i_ce, i_input, i_lgcoeff, o_err, o_dbg);
	parameter		PHASE_BITS = 32;
	parameter	[0:0]	OPT_TRACK_FREQUENCY = 1'b1;
	localparam		MSB=PHASE_BITS-1;
	//
	input	wire	i_clk;
	//
	input	wire			i_ld;
	input	wire	[(MSB-1):0]	i_step;
	//
	input	wire			i_ce;
	input	wire			i_input;
	input	wire	[4:0]		i_lgcoeff;
	output	reg	[1:0]		o_err;
	//
	output	wire	[13:0]		o_dbg;

	reg		agreed_output, phase_err, lead;	// lag
	reg	[MSB:0]	ctr, phase_correction, freq_correction, r_step;

	initial	agreed_output = 0;
	always @(posedge i_clk)
	if (i_ce)
	begin
		if ((i_input)&&(ctr[MSB]))
			agreed_output <= 1'b1;
		else if ((!i_input)&&(!ctr[MSB]))
			agreed_output <= 1'b0;
	end

	//
	// Lead is true if the counter changes before the input
	// changes, false otherwise
	//
	always @(*)
		if (agreed_output)
			// We were last high.  Lead is true now
			// if the counter goes low before the input
			lead = (!ctr[MSB])&&(i_input);
		else
			// The last time we agreed, both the counter
			// and the input were low.   This will be
			// true if the counter goes high before the input
			lead = (ctr[MSB])&&(!i_input);

	// Any disagreement between the high order counter bit and the input
	// is a phase error that we will need to correct
	assign	phase_err = (ctr[MSB] != i_input);

	// How much we correct our phase by is a function of our loop
	// coefficient, here represented by 2^{-i_lgcoeff}.
	initial	phase_correction = 0;
	always @(posedge i_clk)
		phase_correction <= {1'b1,{(MSB){1'b0}}} >> i_lgcoeff;

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
				ctr <= ctr + r_step - phase_correction;

			// Likewise, if the counter is falling behind the input,
			// then we need to speed it up.
			else // if (lag)
				ctr <= ctr + r_step + phase_correction;
		end

	// The frequency correction needs to be the phase_correction squared
	// divided by four in order to get a critically damped loop
	initial	freq_correction = 0;
	always @(posedge i_clk)
		freq_correction <= { 3'b001, {(MSB-2){1'b0}} } >> (2*i_lgcoeff);

	always @(posedge i_clk)
		if ((i_ld)||(!OPT_TRACK_FREQUENCY))
			r_step <= { 1'b0, i_step };
		else if ((phase_err)&&(lead))
			r_step <= r_step - freq_correction;
		else if ((phase_err)&&(!lead))
			r_step <= r_step + freq_correction;

	initial	o_err = 2'h0;
	always @(posedge i_clk)
	if (i_ce)
		o_err <= (!phase_err) ? 2'b00 : ((lead) ? 2'b11 : 2'b01);

	boxcar #(.IW(2), .LGMEM(12))
		bcar(i_clk, 1'b0, 12'heff, i_ce, o_err, o_dbg);
endmodule
