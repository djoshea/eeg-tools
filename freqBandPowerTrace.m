function [powtrace freqHz] = freqBandPowerTrace(epochs, smoothwidth)
% [powtrace freqHz] = freqBandPowerTrace(epochs, smoothwidth)
% plots power density in standard EEG frequency bands over time

if(~exist('smoothwidth','var'))
    smoothwidth = 60; % bigger = smoother
end

%% set up frequency bands and info
freqHz = [0.25, 2; ...   % delta
             2, 8; ...   % theta
             8, 13;...   % alpha
             13, 20;...  % beta
             20, 50; ];  % gamma
freqName = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
freqColor = [0.18 1 1; ...
             .471 .376 0; ...
             .118 .973 0; ...
             .878 .035 1; ...
             .816 0 0];
         
nfreq = size(freqHz,1);

%% process data set
nepoch = size(epochs.fft,1);

powtrace = zeros(nepoch, nfreq);
for f = 1:nfreq
    freqbins = epochs.freqbands >= freqHz(f,1) & epochs.freqbands < freqHz(f,2);
    powtrace(:,f) = sum(epochs.fft(:, freqbins),2) / (freqHz(f,2)-freqHz(f,1));
end

%% reject outliers from obvious artifacts

maxzscore = 5;
reject = sum(abs(zscore(powtrace)),2) > maxzscore;
powtrace(reject,:) = NaN;
disp('Rejected %d epochs due to artifacts', sum(reject));

%% plot smoothedband power vs. time traces

figure(1), clf;
hold on
thour = epochs.sec / 3600;
for f = 1:nfreq
   plot(thour, smooth(powtrace(:,f),smoothwidth), '-',...
       'LineWidth', 2, 'Color', freqColor(f,:));
end

ylabel('Mean Power Spectral Density uV^2 / Hz');
xlabel('Time (hr)');
xlim([0 max(thour)]);
title('Band Power Density vs. Time');
box off

legend(freqName, 'Location', 'Best');