fnumstr = '0012';
fname = sprintf('2010_04_22_%s.abf',fnumstr);

dosave = 1;

[d si h] = abfload(fname);

rtn = squeeze(d(:,1,:));
pfc = squeeze(d(:,2,:));
if(size(d,2) > 2)
    laser = squeeze(d(:,3,:));
else
    laser = 0*rtn;
end

npts = size(d,1);
sis = si*10^-6; % sampling interval in sec
Fs = 1/sis;
t = 0:sis:npts*sis-sis; % time trace
wn = Fs/2; % nyquist frequency

freqLow = 0.3; % Hz
freqHigh = 300; % Hz

freqLow = 20;
freqHigh = 30;

% downsample to 1 kHz (reduces filtering time)
% dsHz = 2000;
% rtnDS = resample(rtn,dsHz,round(Fs));
% pfcDS = resample(pfc,dsHz,round(Fs));

ds = 16;
if(ds)
    if(ds == 4)
        dsHz = Fs/4;
        dsfun = @(sig) decimate(sig,4);
    else
        dsHz = Fs/16;
        dsfun = @(sig) decimate(decimate(sig,4),4);
    end
    
    fprintf('Downsampling to %d Hz...\n', round(dsHz));
    
    rtnCell = mat2cell(rtn,size(rtn,1), ones(size(rtn,2),1));
    pfcCell = mat2cell(pfc,size(pfc,1), ones(size(pfc,2),1));
    rtnDS = cell2mat(cellfun(dsfun,rtnCell,'UniformOutput',false));
    pfcDS = cell2mat(cellfun(dsfun,pfcCell,'UniformOutput',false));
    tDS = 0:1/dsHz:(length(rtnDS)-1)/dsHz;
    
    laserDS = dsfun(laser(:,1));
else
    dsHz = Fs;
     rtnDS = rtn;
    pfcDS = pfc;
    tDS = 0:1/dsHz:(length(rtnDS)-1)/dsHz;
    
    laserDS = laser(:,1);
end

if(strcmp(fnumstr, '0012'))
    disp('Using 7.5s ON 7.5s OFF...');
    ton = tDS >= 0.5 & tDS < 7.5;
    toff = tDS >= 7.5 & tDS < 14.5;
else
    disp('Using 15s ON 15s OFF...');
    ton = tDS >= 0.5 & tDS <= 15.5;
    toff = tDS > 15.5 & tDS < 30.5;
end
 
%%
figure(1), clf; set(1,'Color',[1 1 1]);
plot(tDS(ton),laserDS(ton,1),'b-');
hold on
plot(tDS(toff),laserDS(toff,1),'-','Color',[0.5 0.5 0.5],'LineWidth',2);
xlabel('Time (s)');
ylabel('Laser Signal');
title('Laser Protocol');
legend({'Laser ON', 'Laser OFF'},'Location','Best');
legendboxoff
box off

if(dosave)
    fname = sprintf('laser trace %s.png', fnumstr);
    fprintf('Saving %s...\n', fname);
    print(1, '-dpng', fname);
end

return;

%% Bandpass filter 

% sampling rate
freqBP=[0 0.5 300 350];  % band limits
A=[0 1 0];                % band type: 0='stop', 1='pass'
dev=[0.0001 10^(0.1/20)-1 0.0001]; % ripple/attenuation spec
[M,Wn,beta,typ]= kaiserord(freqBP,A,dev,dsHz);  % window parameters
Fbp=fir1(M,Wn,typ,kaiser(M+1,beta),'noscale'); % filter design

% plot frequency response of filter
% figure(2), clf;
% freqz(Fbp,1,100,dsHz);

% zero-phase filter the response
disp('Filtering RTN...');
rtnBP = filtfilt(Fbp,1,rtnDS);
disp('Filtering PFC...');
pfcBP = filtfilt(Fbp,1,pfcDS);

rtnBP = zscore(rtnBP);
pfcBP = zscore(pfcBP);

%% plot filtered signals

laser = laser / max(laser(:));

figure(3), clf;
h = [];
h(1) = subplot(2,1,1);
plot(t,rtn(:,1)/max(rtn(:,1)),'b-');
hold on
plot(t,pfc(:,1)/max(pfc(:,1)),'g-');
legend({'RTN','PFC'},'Location','Best')
h(2) = subplot(2,1,2);
plot(t,laser(:,1),'r-');
zoom xon
linkaxes(h,'x');
xlabel('Time (s)');
xlim([0 max(tDS)]);

%% Spectra estimates

% disp('Computing spectra for RTN...');
% params.Fs = Fs;
% params.fpass = [0 dsHz/2];
% params.tapers = [3 5];
% [rtnSpect fspect] = mtspectrumc(rtn,params);
% params.Fs = dsHz;
% [rtnBPSpect fBPspect] = mtspectrumc(rtnBP,params);

%% generate proof-of-concept plots
% figure(3), clf;
% h = [];
% h(1) = subplot(2,1,1);
% plot(t,rtn,'b-');
% hold on
% plot(tDS,rtnBP,'g-','LineWidth',2);
% zoom xon
% xlabel('Time (s)');
% xlim([0 max(tDS)]);
% title('RTN (Pre/Post Bandpass)');
% 
% h(2) = subplot(2,1,2);
% plot(t,pfc,'b-');
% hold on
% plot(tDS,pfcBP,'r-','LineWidth',2);
% zoom xon
% xlim([0 max(tDS)]);
% xlabel('Time (s)');
% title('PFC (Pre/Post Bandpass)');
% linkaxes(h,'x');
% 
% figure(4), clf;
% subplot(2,1,1);
% plot_vector(rtnSpect,fspect);
% title('RTN Power Spectrum Original');
% ylim([-120 0]);
% subplot(2,1,2);
% plot_vector(rtnBPSpect, fBPspect);
% title('RTN Power Spectrum Bandpass');
% ylim([-120 0]);

%% Coherency analysis

