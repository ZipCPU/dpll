%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Filename: 	stbpll.m
%%
%% Project:	A collection of phase locked loop (PLL) related projects
%%
%% Purpose:	This file is an Octave script.  It is designed to plot the
%%		outputs of the stbpll_tb test bench program.
%%
%% Creator:	Dan Gisselquist, Ph.D.
%%		Gisselquist Technology, LLC
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Copyright (C) 2018, Gisselquist Technology, LLC
%%
%% This program is free software (firmware): you can redistribute it and/or
%% modify it under the terms of the GNU General Public License as published
%% by the Free Software Foundation, either version 3 of the License, or (at
%% your option) any later version.
%%
%% This program is distributed in the hope that it will be useful, but WITHOUT
%% ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
%% FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
%% for more details.
%%
%% You should have received a copy of the GNU General Public License along
%% with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
%% target there if the PDF file isn't present.)  If not, see
%% <http://www.gnu.org/licenses/> for a copy.
%%
%% License:	GPL, v3, as defined and found on www.gnu.org,
%%		http://www.gnu.org/licenses/gpl.html
%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%
fid = fopen('stbpll.32t','r');
data = fread(fid, [8 inf], 'int32');
fclose(fid);

iphase   = data(1,:);
r_step   = data(2,:);
istb     = data(3,:);
ctr      = data(4,:);
dphase   = data(5,:);
ostb     = data(6,:);
err      = data(7,:);
fltrderr = data(8,:);
truestep = 0x314159;

t = (1:length(dphase))-1;

%
% Figure #1: Showing the phase error.  If this works, the phase error should
% converge to zero.  The better/faster this works, the faster the phase error
% should converge towards zero.
%
figure(1);
plot(t, dphase); grid on;
axis([0 15000 -2.4e9 2.4e9]);
ylabel('Actual phase error');
xlabel('Time step');

%
%
% Figure #2: The step size.  This is inversely proportional to frequency, and
% I need to be careful that I don't confuse the terms for the two.  The two
% step sizes, the estimate and the truth, are plotted together.  Convergence
% is good, fast convergence is better.
%
%
figure(2);
plot(t, r_step, ';Estimate;', [min(t),max(t)], truestep * [1 1], ';Truth;'); grid on;
% axis([0 15000 8e8 9.5e8]);
ylabel('Frequency step');
xlabel('Time step');

%
% Figure #3: The averaged error, produced by running the error signal through
% a block averager.  This should converge to zero if all works well.
%
%
figure(3);
plot(t, fltrderr); grid on;
axis([0 15000 -500 100]);
ylabel('Averaged error');
xlabel('Time step');

%
%
% Figure #4: The raw error signal, of which figure 3 shows the average.  This
% tends to be difficult to interpret, as it's hard to see this converge towards
% anything.
%
%
figure(4);
plot(t, err); grid on;
axis([0 15000 -2 2]);
ylabel('Measured Error');
xlabel('Time step');

%
%
% Figure #5: The incoming and outgoing strobe signals.  If all goes well, once
% the PLL converges these two signals will be identical.  Because this can be
% difficult to see, the outgoing strobe signal has been negated.
%
%
figure(5);
plot(t, istb, ';Incoming;', t, ostb,';Outgoing;'); grid on;
axis([0 15000 -2 2]);
% axis([49800 50000 -2 2]);
ylabel('Strobes');
xlabel('Time step');


