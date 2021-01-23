%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Filename: 	quadpll_tb.m
%%
%% Project:	A collection of phase locked loop (PLL) related projects
%%
%% Purpose:	This file is an Octave script.  It is designed to plot the
%%		outputs of the quadpll_tb test bench program.
%%
%% Creator:	Dan Gisselquist, Ph.D.
%%		Gisselquist Technology, LLC
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Copyright (C) 2017-2021, Gisselquist Technology, LLC
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
fid = fopen('quadpll.32t','r');
data = fread(fid, [7 inf], 'int32');
fclose(fid);

iphase   = data(1,:);
r_step   = data(2,:);
input    = data(3,:);
err      = data(4,:);
ctr      = data(5,:);
dphase   = data(6,:);
fltrderr = data(7,:);

t = (1:length(dphase))-1;

figure(1);
plot(t, dphase); grid on;
axis([0 15000 -2.4e9 2.4e9]);
ylabel('Actual phase error');
xlabel('Time step');

figure(2);
plot(t, r_step); grid on;
axis([0 15000 8e8 9.5e8]);
ylabel('Frequency step');
xlabel('Time step');

figure(3);
plot(t, fltrderr); grid on;
axis([0 15000 -500 100]);
ylabel('Averaged error');
xlabel('Time step');

figure(4);
plot(t, err); grid on;
axis([0 15000 -2 2]);
ylabel('Measured Error');
xlabel('Time step');


