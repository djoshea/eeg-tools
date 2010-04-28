function [powtrace freqHz] = freqBandPowerTrace(epochs, smoothwidth)
% [powtrace freqHz] = freqBandPowerTrace(epochs, smoothwidth)
% plots power density in standard EEG frequency bands over time
% will also plot epochs.laser and epochs.anesthetic

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
plotBands = [ 1 1 1 1 1];
freqColor = [0.18 1 1; ...
             .471 .376 0; ...
             .118 .973 0; ...
             .878 .035 1; ...
             .816 0 0];

% freqName = { 'beta', 'gamma'};
% freqHz = [13, 20;...  % beta
%  20, 50; ];  % gamma
         
nfreq = size(freqHz,1);

scoreLabels = {'IE', 'BU', 'SW', 'W', 'F1','None'};
scoresInclude = {'W','SW', 'BU', 'IE'};
% scoresInclude = {'None'};
scoreColors = jet(length(scoreLabels));
nscore = length(scoreLabels);

%% process data set
nepoch = size(epochs.fft,1);

% sum power in each frequency band
powtrace = zeros(nepoch, nfreq);
for f = 1:nfreq
    freqbins = epochs.freqbands >= freqHz(f,1) & epochs.freqbands < freqHz(f,2);
    powtrace(:,f) = sum(epochs.fft(:, freqbins),2) / (freqHz(f,2)-freqHz(f,1));
end

% create score index list
epochScore = zeros(nepoch,1);
epochScore(:) = NaN;
for s = 1:nscore
   epochsThisScore = cellfun(@(str) strcmp(scoreLabels{s},str), epochs.score);
   epochScore(epochsThisScore) = s;
end

%% reject outliers from obvious artifacts

% reject outright epochs marked as follows
artifactScore = 'F1';
artifactScoreIndex = find(cellfun(@(str) strcmp(artifactScore,str), scoreLabels));
reject = epochScore == artifactScoreIndex;

% reject epochs who are significantly outside the normal power range
% by summing the z-scores in all frequency bands
maxzscore = Inf;
reject = reject | sum(abs(zscore(powtrace)),2) > maxzscore;
fprintf('Rejected %d/%d epochs due to artifacts\n', sum(reject), nepoch);

% list rejected epoch timestamps
rejected = find(reject);
for i = 1:length(rejected)
   fprintf('\t%s\n', epochs.timestr{rejected(i)});
end

% include only epochs scored as in scoresInclude
include = zeros(nepoch,1);
for i = 1:length(scoresInclude)
   scoreIndex = find(cellfun(@(str) strcmp(scoresInclude(i),str), scoreLabels));
   include = include | (epochScore == scoreIndex);
end

reject = reject | ~include;

powtrace(reject,:) = NaN;
% epochScore(reject) = NaN;

%% plot smoothedband power vs. time traces

figure(1), clf;

h1 = subplot(3,1,1:2);
hold on
thour = epochs.sec / 3600 * 60;
for f = 1:nfreq
    if(~plotBands(f))
        continue;
    end
    if(smoothwidth > 1)
        smoothed = smooth(powtrace(:,f), smoothwidth);
    else
        smoothed = powtrace(:,f);
    end
    smoothed(reject) = NaN;
    smoothed = smoothed / max(smoothed);
    plot(thour, smoothed, '-',...
       'LineWidth', 2, 'Color', freqColor(f,:));
end

ylabel('Normalized Power Spectral Density');
xlabel('Time (min)');
xlim([0 max(thour)]);
title('Band Power Density vs. Time');
box off
legend(freqName, 'Location', 'Best');
legendboxoff

h2 = subplot(3,1,3);
hold on
plot(thour, epochScore, '-', 'LineWidth', 2, 'Color', [0.2 0.2 0.2]);

% add laser and anesthetic plots if found
extraTicks = 0;
ticks = scoreLabels;
if(isfield(epochs, 'laser'))
    extraTicks = extraTicks + 1;
    plot(thour(epochs.laser), nscore+extraTicks, 'b.');
    ticks{end+1} = 'Laser';
end
if(isfield(epochs, 'anesthetic'))
    extraTicks = extraTicks + 1;
    plot(thour(epochs.anesthetic), nscore+extraTicks, '.', 'Color', [0.5 0.5 0.5]);
    ticks{end+1} = 'Anesthetic';
end
set(gca, 'YTick', 1:nscore+extraTicks);
set(gca, 'YTickLabel', ticks);

ylabel('Sleep Stage');
xlabel('Time (min)');
xlim([0 max(thour)]);

linkaxes([h1 h2], 'x');