% Script validation_stationary_loudness_synthetic_signals
%
% This code computes stationary loudness from the reference signals provided 
%   in ISO 532-1:2017 - Annex B.2. (signal 1, defined as one-third octave 
%   band levels) and Annex B.3 (signals 2 to 5, stored as wave files) and 
%   plots the comparison between the values obtained from SQAT (function
%   Loudness_ISO532_1) and the corresponding reference values.
%
% Loudness computed using:
%   OUT = Loudness_ISO532_1(insig, fs, field, method, time_skip, show)
%   type <help Loudness_ISO532_1> for more info
%
% In order to run this code, the user needs to download the dataset of 
%  sound files from zenodo (https://doi.org/10.5281/zenodo.7933206).
%  The obtained folder called `validation_SQAT_v1_0` has to be included in 
%  the `sound_files` folder of the toolbox. 
%
% Author: Gil Felix Greco, Braunschweig 27.02.2023
% modifided in 07.12.2024 by Gil Felix Greco - included plot with summary of differences between reference and calculated loudness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear all; close all;

%% save figs flag

save_figs = 0;
                                  
%% validation signals 1 to 5
%       signal 1 is a numeric array, specified as one-third octave band levels
%       signals 2-5 are wave files.
signal_str= {[-60 -60 78 79 89 72 80 89 75 87 85 79 86 80 71 70 72 71 72 74 69 65 67 77 68 58 45 30], ... % 1/3 octave levels provided by ISO 532-1:2017 - Annex B.2.  
             'Test signal 2 (250 Hz 80 dB).wav',...
             'Test signal 3 (1 kHz 60 dB).wav',...
             'Test signal 4 (4 kHz 40 dB).wav',...
             'Test signal 5 (pinknoise 60 dB).wav'}; % name of the input signals
 
num_signals = length(signal_str);

for i=1:num_signals

    [OUT.L{i},OUT.RefScalar{i}]=il_compute_and_plot(i,...     % insig_num
                                            signal_str{i},... % insig name str
                                             save_figs);      % savefig inputs
end
disp('')

%% summary of differences between reference and calculated loudness

% test signals
X = categorical({'1','2','3','4','5'});

% create vector with loudness differences of all test signals  
for i = 1:length(X)
    diff_vector(i) = OUT.RefScalar{i}(1,3);
end

title_fig = sprintf('Loudness - summary of differences between ref. and calculated values');
h = figure('Name',title_fig);
set(h,'Units','Inches');
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])

plot(X, diff_vector, 'x', 'Markersize', 12);

tolerance = 0.1;
handle_a = yline(  tolerance, '--r'); % plot tolerance of N=1 sone stipulated by the ISO norm
yline( -tolerance, '--r');

ymin = -0.2; ymax = 0.2;
ylim([ymin ymax]);

ylabel('$\Delta N$ (sone)','Interpreter','Latex');
xlabel('Test signal','Interpreter','Latex');

legend(handle_a, 'ISO 532-1:2017 tolerance');
legend box off

grid off
set(gcf,'color','w');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if save_figs==1

    figures_dir = [pwd filesep 'figs' filesep];

    if ~exist(figures_dir,'dir')
        mkdir(figures_dir);
    end
    
    figname_short = 'validation_stationary_signals_loudness_difference';
    figname_out = [figures_dir figname_short];
    
    % saveas(gcf,figname_out, 'fig');
    % saveas(gcf,figname_out, 'pdf');
    saveas(gcf,figname_out, 'png');
    
    fprintf('\n%s.m: figure %s was saved on disk\n\t(full name: %s)\n',mfilename,figname_short,figname_out);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% function (compute loudness and plot comparison

function [OUT,table] = il_compute_and_plot(insig_num,fname_insig,save_figs)
% function [OUT,table] = il_compute_and_plot(insig_num,fname_insig,save_figs)
%
% this function computes the loudness using SQAT and plot the comparison
% against the reference values from the ISO 532-1:2017 - Annex B.3. 
%
% INPUTS:
%   insig_num : scalar
%       number of the reference signal to be tested
%
%   insig : string
%       name of the reference signals
%
%   save_figs : scalar
%       1 to save; <else> dont save figures 
%
%   tag : string
%       tag with the name of the figures to be saved
%
% OUTPUTS:
%   OUT : struct
%       contain all outputs from the computed loudness
%
%   table : matrix containing scalar values of total loudness, N (1st row)
%   and loudness levels, LN (2nd row)
%           1st column=reference
%           2nd column=computed by SQAT
%           3rd column=difference (SQAT minus ref.)
%           4th column=relative percentage difference (SQAT minus ref.)
%
% Author: Gil Felix Greco, Braunschweig 27.02.2023
% modifided in 07.12.2024 by Gil Felix Greco - included difference as an output of <table> 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% signals from ISO 532-2:2017

dir_analysis_name = '1_synthetic_signals_stationary_loudness';
dir_out = [fileparts(mfilename('fullpath')) filesep];

if isnumeric(fname_insig)
    bFrom_wav_file = 0;
    insig = fname_insig;
else
    bFrom_wav_file = 1;
end
    
SQAT_version=1; % v1.0
dir_sounds = get_dir_validation_sounds('Loudness_ISO532_1',SQAT_version);
dir_ref_values = get_dir_reference_values('Loudness_ISO532_1',dir_analysis_name);

if bFrom_wav_file
    % calculate stationary loudness using SQAT for signals 2 to 5, method == 1
    
    % calibration signal provided in the Annex C of the ISO 532-1:2017

    [RefSignal,~]=audioread([dir_sounds 'calibration signal sine 1kHz 60dB.wav']);
    
    %%% Calibration using the concept of dB full scale:
    lvl_cal_signal = 60;                               % from file name: 'calibration signal sine 1kHz 60dB.wav'
    dBFS_in = lvl_cal_signal-20*log10(rms(RefSignal)); % difference between target and actual full-scale value 
    dBFS_out = 94; % dB full scale convention in SQAT: amplitude of 1 = 1 Pa, or 94 dB SPL
    dB_correction = dBFS_in - dBFS_out;
    
    % Test signal provided in the Annex B.3 of the ISO 532-1:2017
    
    [insig,fs]=audioread([dir_sounds fname_insig]);

    %%% Calibration using Gil's script:
    % % calibrated .wav signal
    % [insig_cal]=calibrate(insig,RefSignal,60); 
    insig_cal = insig * 10^(dB_correction/20);
    SPL = 20.*log10(rms(insig_cal)/2e-5); % verify final SPL of the signal
    
    % Stationary loudness calculation from input audio signal using SQAT
    
    OUT = Loudness_ISO532_1( insig_cal, fs,...   % input signal and sampling freq.
                                    0,...   % field; free field = 0; diffuse field = 1;
                                    1,...   % method; stationary (from input 1/3 octave unweighted SPL)=0; stationary = 1; time varying = 2; 
                                    0,...   % time_skip, in seconds for level (stationary signals) and statistics (stationary and time-varying signals) calculations
                                    0);     % show results, 'false' (disable, default value) or 'true' (enable)

else % calculate stationary loudness for signal 1 (input from 1/3 octave band) , method == 0
    
    OUT = Loudness_ISO532_1( insig, 1,...   % input signal and sampling freq.
                                    0,...   % field; free field = 0; diffuse field = 1;
                                    0,...   % method; stationary (from input 1/3 octave unweighted SPL)=0; stationary = 1; time varying = 2; 
                                    0,...   % time_skip, in seconds for level (stationary signals) and statistics (stationary and time-varying signals) calculations
                                    0);     % show results, 'false' (disable, default value) or 'true' (enable)

end

%% calculate difference from reference values given by ISO 532-1:2017

% reference values provided by ISO 532-1:2017 for signals 1 to 5 
reference_loudness       = [83.296 14.655 4.019 1.549 10.498];   
reference_loudness_level = [103.802 78.733 60.069 46.317 73.920]; 

reference_loudness=reference_loudness(insig_num); % take ref values from the current signal number
reference_loudness_level=reference_loudness_level(insig_num);

% compute difference (SQAT minus ref.)
difference_loudness = OUT.Loudness - reference_loudness;
difference_loudness_level = OUT.LoudnessLevel - reference_loudness_level;

% compute relative percentage difference (SQAT minus ref.)
percentage_difference_loudness=( (OUT.Loudness-reference_loudness)/reference_loudness )*100;
percentage_difference_loudness_level=( (OUT.LoudnessLevel-reference_loudness_level)/reference_loudness_level )*100;

% write results in a table format (1st col=reference; 2nd col=computed by SQAT; 3rd col=difference (SQAT minus ref.;) 4th col=relative percentage difference (SQAT minus ref.))
% 1st row = total loudness, 2nd row = loudness levels
table=[ reference_loudness, OUT.Loudness, difference_loudness, percentage_difference_loudness;
            reference_loudness_level, OUT.LoudnessLevel, difference_loudness_level, percentage_difference_loudness_level ];

%% plot results (specific loudness)

title_fig = sprintf('Loudness - signal %g',insig_num);
h = figure('Name',title_fig);
set(h,'Units','Inches');
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])

reference = []; % to be loaded in the next line...
fname = sprintf('%sreference_values_ISO532_1_2017_signal_%g.mat', dir_ref_values, insig_num);
load(fname); % load reference vectors

% reference values 

% plot( reference(:,1), reference(:,2),'b','Linewidth',0.5); % ref N'
handle_a=plot( reference(:,1), reference(:,3),'r:','Linewidth',1); hold on; % ref N'_min
plot( reference(:,1), reference(:,4),'r:','Linewidth',1); % ref N'_max

% SQAT values

handle_b=plot( OUT.barkAxis, OUT.SpecificLoudness,'k','Linewidth',1); % calculated specific loudness

legend([handle_a,handle_b],'5\% tolerance','SQAT','Location','Best');

ylabel('Specific loudness, $N^{\prime}~(\mathrm{sone}/\mathrm{Bark})$','Interpreter','Latex');
xlabel('Critical band, $z$ (Bark)','Interpreter','Latex'); 

grid off

set(gcf,'color','w');

if save_figs==1
    if ~exist(dir_out,'dir')
        mkdir(dir_out);
    end
    figures_dir = [dir_out 'figs' filesep];
    if ~exist(figures_dir,'dir')
        mkdir(figures_dir);
    end
    figname_short = sprintf('validation_stationary_loudness_signal_%g',insig_num);
    figname_out = [figures_dir figname_short];
    
    % saveas(gcf,figname_out, 'fig');
    % saveas(gcf,figname_out, 'pdf');
    saveas(gcf,figname_out, 'png');
    
    fprintf('\n%s.m: figure %s was saved on disk\n\t(full name: %s)\n',mfilename,figname_short,figname_out);
end

end
