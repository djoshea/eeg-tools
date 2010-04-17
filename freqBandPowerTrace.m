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

scoreLabels = {'IE', 'BU', 'SW', 'W'};
scoreColors = jet(length(scoreLabels));
nscore = length(scoreLabels);

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
fprintf('Rejected %d/%d epochs due to artifacts\n', sum(reject), nepoch);

%% plot smoothedband power vs. time traces

figure(1), clf;

subplot(3,1,1:2);
hold on
thour = epochs.sec / 3600;
for f = 1:nfreq
   plot(thour, smooth(powtrace(:,f),smoothwidth), '-',...
       'LineWidth', 2, 'Color', freqColor(f,:));
end

ylabel('Mean Power Spectral Density uV^2 / Hz');
xlabel('Time (hr)');
xlim([0 max(thour)]);
title('Band Power Density vs. Time: EMG');
box off
legend(freqName, 'Location', 'Best');

epochScore = zeros(nepoch,1);
epochScore(:) = NaN;
subplot(3,1,3);
hold on
for s = 1:nscore
   epochsThisScore = cellfun(@(str) strcmp(scoreLabels{s},str), epochs.score);
   plot(thour(epochsThisScore), s, 'o', 'MarkerSize', 4, ...
       'Color', scoreColors(s,:), 'MarkerFaceColor', scoreColors(s,:));
   epochScore(epochsThisScore) = s;
end

cla
hold on
for e = 1:nepoch-1
    if(~isnan(epochScore(e)) && ~isnan(epochScore(e+1)))
        line([thour(e) thour(e+1)], [epochScore(e) epochScore(e+1)], ...
           'LineWidth', 2, 'Color', [0.2 0.2 0.2]);
    end
end
set(gca, 'YTick', 1:nscore);
set(gca, 'YTickLabel', scoreLabels);
ylabel('Sleep Stage');
xlabel('Time (hr)');
xlim([0 max(thour)]);