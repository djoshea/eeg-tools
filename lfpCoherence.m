params = [];
params.Fs = dsHz;
params.fpass = [0 140];
params.tapers = [10 19];
params.err = [2 0.05];
params.pad = 1;
params.trialave = 1;

figure(4), clf;

rtnDS = zscore(rtnDS);
pfcDS = zscore(pfcDS);

disp('Computing coherence for laser OFF...');
[Coff,phioff,S12off,S1off,S2off,foff,confCoff,phistdoff,Cerroff] = ...
    coherencyc(rtnDS(toff,:),pfcDS(toff,:),params);

if(nnz(ton))
    disp('Computing coherence for laser ON...');
    [Con,phion,S12on,S1on,S2on,fon,confCon,phistdon,Cerron] = ...
        coherencyc(rtnDS(ton,:),pfcDS(ton,:),params);
end
%% plot coherence vs. frequency


figure(3), clf;
h = [];
plot(foff, Coff, '-', 'LineWidth', 2, 'Color', [0.5 0.5 0.5]);
if(nnz(ton))
    hold on
    plot(fon, Con, 'b-', 'LineWidth', 2);
    shadeSpectra(fon,Con,Cerron,'b',0);
end

shadeSpectra(foff,Coff,Cerroff,[0.5 0.5 0.5],0);
title('PFC / RTn Coherence');
xlabel('Frequency (Hz)');
ylabel('Coherence');
ylim([0 1]);
if(nnz(ton))
    legend({'Laser Off', 'Laser On'},'Location','NorthEast');
    legendboxoff
end
box off

fname = sprintf('coherence %s DS %d tapers %d %d.png',...
    fnumstr, ds, params.tapers(1), params.tapers(2));
fprintf('Saving %s...\n', fname);
print(3, '-dpng', fname);

if(nnz(ton))
    % plot difference in coherence directly
    delta = Con-Coff;
    shadehilo = Cerron - Cerroff([2 1],:);

    figure(4), clf;
    h = [];
    plot(foff, delta, 'k-', 'LineWidth', 1);
    hold on
    shadeSpectra(foff,delta,shadehilo,[0 0 0],0);
    plot([0 max(foff)], [0 0], '--', 'Color', [0.5 0.5 0.5]);
    title('PFC / RTn Coherence: Laser ON - Laser OFF');
    xlabel('Frequency (Hz)');
    ylabel('Change in Coherence');
    % ylim([min? 1]);
    box off

    fname = sprintf('coherence delta %s DS %d tapers %d %d.png',...
        fnumstr, ds, params.tapers(1), params.tapers(2));
    fprintf('Saving %s...\n', fname);
    print(4, '-dpng', fname);
end

