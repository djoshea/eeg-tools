dosave = 1;

params = [];
params.Fs = dsHz;
params.trialave = 1;
params.fpass = [0 140];
params.tapers = [10 19];
params.err = [2 0.05];
params.pad = 1;

rtnDS = zscore(rtnDS);
pfcDS = zscore(pfcDS);

% rtnDS = zscore(rtnBP);
% pfcDS = zscore(pfcBP);

disp('Computing RTn spectra for laser OFF...');
[rtnSpectOff frtnOff rtnSpectOffErr] = mtspectrumc(rtnDS(toff,:),params);
disp('Computing PFC spectra for laser OFF...');
[pfcSpectOff fpfcOff pfcSpectOffErr] = mtspectrumc(pfcDS(toff,:),params);

if(nnz(ton))
    disp('Computing RTn spectra for laser ON...');
    [rtnSpectOn frtnOn rtnSpectOnErr] = mtspectrumc(rtnDS(ton,:),params);
    disp('Computing PFC spectra for laser ON...');
    [pfcSpectOn fpfcOn pfcSpectOnErr] = mtspectrumc(pfcDS(ton,:),params);
end

laserspectra = 0;
if(laserspectra && exist('laserDS','var'))
    disp('Computing laser spectra for laser OFF...');
    [laserSpectOff flaserOff] = mtspectrumc(laserDS(toff,:), params);
    disp('Computing laser spectra for laser ON...');
    [laserSpectOn flaserOn] = mtspectrumc(laserDS(ton,:), params);
end

%% 

% plot power spectrum for RTn
figure(2), clf; set(2,'Color',[1 1 1]);
h = [];
h(1) = subplot(2+laserspectra,1,1);
plot(frtnOff, 10*log10(rtnSpectOff), '-', 'LineWidth', 2, 'Color', [0.5 0.5 0.5]);
if(nnz(ton))
    hold on
    plot(frtnOn, 10*log10(rtnSpectOn), 'b-', 'LineWidth', 2);
    shadeSpectra(frtnOn,rtnSpectOn,rtnSpectOnErr,'b');
end

shadeSpectra(frtnOff,rtnSpectOff,rtnSpectOffErr,[0.5 0.5 0.5]);
title('RTN Spectrum');
xlabel('Frequency (Hz)');
ylabel('Log Power (dB)');
if(nnz(ton))
    legend({'Laser Off', 'Laser On'},'Location','NorthEast');
    legendboxoff
end

box off

h(2) = subplot(2+laserspectra,1,2);
plot(fpfcOff, 10*log10(pfcSpectOff), '-', 'LineWidth', 2, 'Color', [0.5 0.5 0.5]);
if(nnz(ton))
    hold on
    plot(fpfcOn, 10*log10(pfcSpectOn), 'b-','LineWidth', 2);
    shadeSpectra(fpfcOn,pfcSpectOn,pfcSpectOnErr,'b');
end

shadeSpectra(fpfcOff,pfcSpectOff,pfcSpectOffErr,[0.5 0.5 0.5]);
title('PFC spectrum');
xlabel('Frequency (Hz)');
ylabel('Log Power (dB)');
if(nnz(ton))
    legend({'Laser Off', 'Laser On'},'Location','NorthEast');
    legendboxoff
end
box off

%% plot laser spectrum
if(laserspectra & exist('laserDS','var'))
    h(3) = subplot(3,1,3);
    plot(flaserOff, 10*log10(laserSpectOff), '-', 'LineWidth', 2, 'Color', [0.5 0.5 0.5]);
    hold on
    plot(flaserOn, 10*log10(laserSpectOn), 'b-','LineWidth', 1);
    title('Laser spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Log Power (dB)');
    legend({'Laser Off', 'Laser On'},'Location','NorthEast');
    legendboxoff
    box off
end

if(dosave)
    fname = sprintf('power %s DS %d tapers %d %d.png',...
        fnumstr, ds, params.tapers(1), params.tapers(2));
    fprintf('Saving %s...\n', fname);
    print(2, '-dpng', fname);
end

%% plot spectrum difference

if(nnz(ton))
    figure(5), clf; set(5,'Color',[1 1 1]);
    h5 = [];
    
    % rtn delta
    h5(1) = subplot(2,1,1);
    delta = 10*log10(rtnSpectOn)-10*log10(rtnSpectOff);
    shadehilo = 10*log10(rtnSpectOnErr) - 10*log10(rtnSpectOffErr([2 1],:));
    
    plot(frtnOff, delta, 'k-', 'LineWidth', 1);
   
    shadeSpectra(frtnOff,delta,shadehilo,[0 0 0],0);
    plot([0 max(frtnOff)], [0 0], '--', 'Color', [0.5 0.5 0.5]);
    title('RTN Spectrum Change: ON minus OFF');
    xlabel('Frequency (Hz)');
    ylabel('Log Power Delta (dB)');
    ylim([-6 12]);
    box off

    % pfc delta
    h5(2) = subplot(2,1,2);
    delta = 10*log10(pfcSpectOn)-10*log10(pfcSpectOff);
    shadehilo = 10*log10(pfcSpectOnErr) - 10*log10(pfcSpectOffErr([2 1],:));

    plot(fpfcOff, delta, 'k-', 'LineWidth', 1);
    shadeSpectra(fpfcOff,delta,shadehilo,[0 0 0],0);
    plot([0 max(fpfcOff)], [0 0], '--', 'Color', [0.5 0.5 0.5]);
    title('PFC Spectrum Change: ON minus OFF');
    xlabel('Frequency (Hz)');
    ylabel('Log Power (dB)');
    box off
    
    linkaxes(h5,'x');
    
    if(dosave)
        fname = sprintf('power delta %s DS %d tapers %d %d.png',...
            fnumstr, ds, params.tapers(1), params.tapers(2));
        fprintf('Saving %s...\n', fname);
        print(5, '-dpng', fname);
    end

end
