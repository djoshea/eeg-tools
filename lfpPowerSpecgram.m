dosave = 1;

params = [];
params.Fs = dsHz;
params.trialave = 1;
params.fpass = [0 55];
params.tapers = [3 5];
params.err = [2 0.05];
params.pad = 1;

twindow = 0.1;
twinstep = twindow/4;
movingwin = [twindow twinstep];

rtnDS = zscore(rtnDS);
pfcDS = zscore(pfcDS);

% rtnDS = zscore(rtnBP);
% pfcDS = zscore(pfcBP);

disp('Computing RTn spectrogram...');
[rtnSpectOff tspec fspec rtnSpectOffErr] = mtspecgramc(rtnDS,movingwin,params);
disp('Computing PFC spectrogram...');
[pfcSpectOff tspec fspec pfcSpectOffErr] = mtspecgramc(pfcDS,movingwin,params);

[T F] = meshgrid(tspec, fspec);

% if(nnz(ton))
%     disp('Computing RTn spectra for laser ON...');
%     [rtnSpectOn tspec fspec rtnSpectOnErr] = mtspecgramc(rtnDS(ton,:),movingwin,params);
%     disp('Computing PFC spectra for laser ON...');
%     [pfcSpectOn tspec fspec pfcSpectOnErr] = mtspecgramc(pfcDS(ton,:),movingwin,params);
% end

laserspectra = 0;
if(laserspectra && exist('laserDS','var'))
    disp('Computing laser spectra for laser OFF...');
    [laserSpectOff tspec fspec] = mtspecgramc(laserDS(toff,:), movingwin, params);
    disp('Computing laser spectra for laser ON...');
    [laserSpectOn tspec fspec] = mtspecgramc(laserDS(ton,:), movingiwin, params);
end

%%

fnum = 7;
figure(fnum), clf; set(fnum,'Color',[1 1 1]);

h1 = subplot(3,1,1);
h = pcolor(T,F,10*log10(rtnSpectOff'));
set(h,'EdgeColor','none');
h = colorbar;
shading interp
set(get(h,'YLabel'),'String','Power (dB)');
ylabel('Frequency (Hz)');
title('RTn Spectrogram');

subplot(3,1,2);
h = pcolor(T,F,10*log10(pfcSpectOff'));
set(h,'EdgeColor','none');
h = colorbar;
shading interp
set(get(h,'YLabel'),'String','Power (dB)');
ylabel('Frequency (Hz)');
title('PFC Spectrogram');

lasertrace = laserDS(:,1);
lasertrace = lasertrace - min(lasertrace);
lasertrace = lasertrace / max(lasertrace);
hlaser = subplot(3,1,3);
plot(tDS,lasertrace,'b-');
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
    fname = sprintf('power spectrogram %s window %.2f tapers %d %d',...
        fnumstr, twindow, params.tapers(1), params.tapers(2));
    fprintf('Saving %s...\n', fname);
    print(fnum, '-dpng','-r300','-painters', fname);
end


return;


