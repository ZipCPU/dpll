////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	ppspll.v
//
// Project:	A collection of phase locked loop (PLL) related projects
//
// Purpose:	A strobe PLL, but one intended to operate on a strobe that
// 		comes only once a second--perhaps every 100M or 1B clock ticks.
// 	Given a this PPS strobe input, this PLL will match match a strobe output
//	and counter to that input.
//
//	Unique features:
//	1. Able to track +/- 1ppb (assuming the incoming strobe is that
//		accurate, and appropriate signals are provided to this core)
//	2. Useful for creating accurate time and frequency creations in an
//		absolute sense.  (Perfect tuning "A" for instance.)
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2018-2019, Gisselquist Technology, LLC
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
module	ppspll(i_clk, i_ld, i_step, i_ce, i_pps, i_pcoef, i_fcoef,
	o_pps, o_phase);
	parameter		STEP_BITS = 24,
				PHASE_BITS = 32+STEP_BITS;
	parameter	[0:0]	OPT_TRACK_FREQUENCY = 1'b1,
				OPT_ASYNCHRONOUS_PPS= 1'b1;
	localparam		PB = PHASE_BITS,
				SB = STEP_BITS;
	//
	input	wire	i_clk;
	//
	input	wire			i_ld;
	input	wire	[(SB-1):0]	i_step;
	//
	input	wire			i_ce;
	input	wire			i_pps;
	input	wire	[PB-1:0]	i_pcoef;
	input	wire	[SB-1:0]	i_fcoef;
	output	reg			o_pps;
	output	wire	[PB-1:0]	o_phase;
	//

	reg	[PB-1:0]	r_counter;
	reg	[SB-1:0]	r_step;

	wire	pps_stb;
	generate if (OPT_ASYNCHRONOUS_PPS)
	begin

		reg	r_pps, r_pipe, r_last, r_pps_stb;

		initial	{ r_last, r_pps, r_pipe } = 3'b0;
		always @(posedge i_clk)
			{ r_pps, r_pipe } <= { r_pipe, i_pps };

		always @(posedge i_clk)
		if (i_ce)
			r_last <= r_pps;

		initial	r_pps_stb = 1'b0;
		always @(posedge i_clk)
		if (i_ce)
			r_pps_stb <= (!r_last)&&(r_pps);
		else
			r_pps_stb <= (r_pps_stb)||((!r_last)&&(r_pps));

		assign	pps_stb = r_pps_stb;

	end else begin

		reg	last_pps;

		initial	last_pps <= 1'b0;
		always @(posedge i_clk)
		if (i_ce)
			last_pps <= i_pps;

		// Positive edge PPS strobe check
		always @(posedge i_clk)
		if (i_ce)
			r_pps_stb <= (!r_last)&&(i_pps);
		else
			r_pps_stb <= (r_pps_stb)||((!r_last)&&(i_pps));

		assign	pps_stb = (!last_pps)&&(i_pps);
		assign	w_pps = i_pps;

	end endgenerate


	///////
	// 
	// 000000000000...
	// 011111111111... clear
	// 100000000000... RX_STB is early
	// 111111111111...
	// 000000000000... PPS_STB
	// 000000000001... RX_STB is late
	// 
	///////

	reg	rcvd_pps;

	reg	p, n, cc;
	reg	[19:0]	load;
	reg	nzload;

	initial	rcvd_pps = 0;
	initial	load = 0;
	always @(posedge i_clk)
	if (i_ce)
	begin
		if ((!r_counter[PB-1])&&(&r_counter[PB-2:SB])&&(cc))
			rcvd_pps <= 1'b0;
		else if (pps_stb)
			rcvd_pps <= 1'b1;

		p <= 0;
		n <= 0;
		cc <= 0;
		if ((rcvd_pps)&&(r_counter[PB-1:PB-2]==2'b11))
		begin
			// r_counter <= r_counter + r_step + i_pcoef;
			// r_step    <= r_step    + i_fcoef;
			{ cc, r_counter[SB-1:0] } <= r_counter[SB-1:0]
					+ r_step + i_pcoef[SB-1:0];
			p <= 1'b1;
		end else if ((nzload)&&(rcvd_pps))
		begin
			// r_counter <= r_counter + r_step - i_pcoef;
			// r_step    <= r_step    - i_fcoef;
			{ cc, r_counter[SB-1:0] } <= r_counter[SB-1:0]
					+ r_step - i_pcoef[SB-1:0];
			n <= 1'b1;
		end else begin
			{ cc, r_counter[SB-1:0] } <= r_counter[SB-1:0]
					+ r_step[SB-1:0];
		end

		if (p)
		begin
			// r_counter <= r_counter + r_step + i_pcoef;
			// r_step    <= r_step    + i_fcoef;
			{ o_pps, r_counter[PB-1:SB] } <= r_counter[PB-1:SB]
					+ i_pcoef[PB-1:SB]
					+ {{(PB-SB-1){1'b0}},cc};
		end else if (n)
		begin
			// r_counter <= r_counter + r_step + i_pcoef;
			// r_step    <= r_step    + i_fcoef;
			{ o_pps, r_counter[PB-1:SB] } <= r_counter[PB-1:SB]
					- i_pcoef[PB-1:SB]
					+ {{(PB-SB-1){1'b0}},cc};
		end else begin
			{ o_pps, r_counter[PB-1:SB] } <= r_counter[PB-1:SB]
					+ {{(PB-SB-1){1'b0}},cc};
			// Step only changes on a measured error
		end

		if ((!rcvd_pps)&&(r_counter[PB-1:PB-2]==2'b00))
		begin
			if (! &load)
				load <= load + 1;
			nzload <= 1'b1;
		end else if ((rcvd_pps)&&(load > 0))
		begin
			load <= load - 1;
			nzload <= (load > 1);
		end else begin // No pulse was received
			load <= 0;
			nzload <= 1'b0;
		end
	end

	always @(posedge i_clk)
	if (i_ld)
		r_step <= i_step;
	else if ((i_ce)&&(rcvd_pps)&&(OPT_TRACK_FREQUENCY))
	begin
		if (r_counter[PB-1])
			r_step <= r_step + i_fcoef;
		else if (nzload)
			r_step <= r_step - i_fcoef;
	end


	reg	[SB-1:0]	last_ctr;
	always @(posedge i_clk)
	if (i_ce)
		last_ctr = r_counter;

	assign	o_phase = { r_counter[PB-1:SB], last_ctr };

endmodule
