%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Filename: 	sdpll.m
%%
%% Project:	A collection of phase locked loop (PLL) related projects
%%
%% Purpose:	This file is an Octave script.  It is designed to plot specific
%%		outputs of the sdpll_tb test bench program.  In particular,
%%	to use this script, you will need to run the program three times:
%%	once with the lgcoeff value set to 4 (move those results to
%%	sdpll-4.32t) with lgcoeff = 5 (move the resulting sdpll.32t file to
%%	sdpll-5.23t), and once with lgcoeff = 6.
%%
%%	Once these three files exist, you can run this script to create several
%%	performance charts.
%%
%% Creator:	Dan Gisselquist, Ph.D.
%%		Gisselquist Technology, LLC
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Copyright (C) 2017-2024, Gisselquist Technology, LLC
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
fid = fopen('sdpll-4.32t','r');
data = fread(fid, [7 inf], 'int32');
fclose(fid);

iphase4   = data(1,:);
r_step4   = data(2,:);
input4    = data(3,:);
err4      = data(4,:);
ctr4      = data(5,:);
dphase4   = data(6,:);
fltrderr4 = data(7,:);

fid = fopen('sdpll-5.32t','r');
data = fread(fid, [7 inf], 'int32');
fclose(fid);

iphase5   = data(1,:);
r_step5   = data(2,:);
input5    = data(3,:);
err5      = data(4,:);
ctr5      = data(5,:);
dphase5   = data(6,:);
fltrderr5 = data(7,:);

fid = fopen('sdpll-6.32t','r');
data = fread(fid, [7 inf], 'int32');
fclose(fid);

iphase6   = data(1,:);
r_step6   = data(2,:);
input6    = data(3,:);
err6      = data(4,:);
ctr6      = data(5,:);
dphase6   = data(6,:);
fltrderr6 = data(7,:);

t = (1:length(dphase4))-1;

figure(1);
plot(
	t, dphase6, '3;i\_lgcoeff=6;',
	t, dphase5, '2;i\_lgcoeff=5;',
	t, dphase4, '1;i\_lgcoeff=4;'
	); grid on;
axis([0 15000 -2.4e9 2.4e9]);
ylabel('Actual phase error');
xlabel('Time step');

figure(2);
plot(
	t, r_step4, '1;i\_lgcoeff=4;',
	t, r_step5, '2;i\_lgcoeff=5;',
	t, r_step6, '3;i\_lgcoeff=6;'); grid on;
axis([0 15000 8e8 9.5e8]);
ylabel('Frequency step');
xlabel('Time step');

figure(3);
plot(
	t, fltrderr4, '1;i\_lgcoeff=4;',
	t, fltrderr5, '2;i\_lgcoeff=5;',
	t, fltrderr6, '3;i\_lgcoeff=6;'); grid on;
axis([0 15000 -500 100]);
ylabel('Averaged error');
xlabel('Time step');

figure(4);
plot(
	t, err4, '1;i\_lgcoeff=4;',
	t, err5, '2;i\_lgcoeff=5;',
	t, err6, '3;i\_lgcoeff=6;'); grid on;
axis([0 15000 -2 2]);
ylabel('Measured Error');
xlabel('Time step');


