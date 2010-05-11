% trigger = 'pulse';
trigger = 'burst';

% calculate laser pulses onsets
laserPulses = diff(laserDS > 0.5*max(laserDS)) == 1;
laserPulseIdx = find(laserPulses);
if(strcmp(trigger,'pulse'));
    % want to split up the dataset by each pulse 
    % ignore the last pulse for symmetry of the first and second displayed pulse 
    laserPulses(find(laserPulses,1,'last')) = 0; 
    trigtimes = tDS(laserPulses);
    trigidx = laserPulseIdx;
    twindow = 0.15;
    twinstep = twindow/10;
else
    % look for large gaps in the pulse times, and pick out the first pulse
    % following a large silence
    laserPulseIntervals = diff([-max(tDS) tDS(laserPulses)]);
    laserBurstIdx = laserPulseIdx(laserPulseIntervals > 2*min(laserPulseIntervals));
    trigtimes = tDS(laserBurstIdx);
    trigidx = laserBurstIdx;
    
    twindow = 0.2;
    twinstep = twindow/10;
end

params = [];
params.Fs = dsHz;
params.trialave = 1;
params.fpass = [0 100];
params.tapers = [3 5];
params.err = [2 0.05];
params.pad = 1;

rtnDS = zscore(rtnDS);
pfcDS = zscore(pfcDS);

movingwin = [twindow twinstep];
    
npulse = length(trigtimes);
ntrial = size(rtnDS,2);
% ntrial = 1;
interval = trigidx(2) - trigidx(1); % interpulse interval in samples
prefix = min(laserBurstIdx(1)-1,floor(0.5 * interval));
postfix = floor(1.5 * interval);
windowpoints = trigidx(2)-prefix:trigidx(2)+postfix-1;

tlaserwindow = tDS(windowpoints) - tDS(trigidx(2));
toffset = tDS(prefix); % for plotting relative to first trigger time
pulsewin = length(windowpoints);

rtnPT = zeros(pulsewin, ntrial*npulse);
pfcPT = zeros(pulsewin, ntrial*npulse);

colidx = 1;
for pulse = 1:npulse
    rtnPT(:,colidx:colidx+ntrial-1) = ...
        rtnDS(trigidx(pulse)-prefix:trigidx(pulse)+postfix-1,1:ntrial);
    pfcPT(:,colidx:colidx+ntrial-1) = ...
        pfcDS(trigidx(pulse)-prefix:trigidx(pulse)+postfix-1,1:ntrial);
    colidx = colidx + ntrial;
end

% rtnDS = zscore(rtnBP);
% pfcDS = zscore(pfcBP);



disp('Computing RTn pulse-triggered spectrogram...');
[rtnSpectOff tspec fspec rtnSpectOffErr] = mtspecgramc(rtnPT,movingwin,params);
disp('Computing PFC pulse-triggered spectrogram...');
[pfcSpectOff tspec fspec pfcSpectOffErr] = mtspecgramc(pfcPT,movingwin,params);

[T F] = meshgrid(tspec - toffset, fspec);

%% plotting 

takelog = 1;
dosave = 0;

fnum = 7;
figure(fnum), clf; set(fnum,'Color',[1 1 1]);

h1 = subplot(3,1,1);
if(takelog)
    h = pcolor(T,F,10*log10(rtnSpectOff'));
    cbarstr = 'Power (dB)';
    plottypestr = 'log';
else
    h = pcolor(T,F,(rtnSpectOff'));
    cbarstr = 'Power (Linear)';
    plottypestr = 'linear';
end
set(h,'EdgeColor','none');
h = colorbar;
% shading interp
set(get(h,'YLabel'),'String',cbarstr);
ylabel('Frequency (Hz)');
title('RTn Spectrogram');
ylim([0 60]);

subplot(3,1,2);
if(takelog)
    h = pcolor(T,F,10*log10(pfcSpectOff'));
else
    h = pcolor(T,F,(pfcSpectOff'));
end
set(h,'EdgeColor','none');
h = colorbar;
% shading interp
set(get(h,'YLabel'),'String',cbarstr);
ylabel('Frequency (Hz)');
title('PFC Spectrogram');
ylim([0 60]);

lasertrace = laserDS(:,1);
lasertrace = lasertrace - min(lasertrace);
lasertrace = lasertrace / max(lasertrace);

hlaser = subplot(3,1,3);
plot(tlaserwindow,lasertrace(windowpoints),'b-');
xlabel('Time (s)');
ylabel('Laser Signal');
set(gca,'YTick',[0 1]);
title('Laser Protocol');
box off

pos = get(h1,'Position');
poslaser = get(hlaser,'Position');
poslaser(3) = pos(3);
set(hlaser,'Position',poslaser);
set(hlaser,'XTick',get(h1,'XTick'));
set(hlaser,'XLim',get(h1,'XLim'));

if(dosave)
    fname = sprintf('power spectrogram triggered %s %s window %.2f %.2f tapers %d %d',...
        plottypestr, fnumstr, twindow, twinstep, params.tapers(1), params.tapers(2));
    fprintf('Saving %s...\n', fname);
    print(fnum, '-dpng','-r300','-painters', fname);
end


return;


