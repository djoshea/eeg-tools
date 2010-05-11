nreps = size(rtnDS,2);
% nreps = 1;
[Pxx F] = periodogram(rtn(t < 10,1),[],[],dsHz);
nfreq = length(Pxx);
P = zeros(nfreq,nreps);

for i = 1:nreps
    P(:,i) = periodogram(rtn(t < 10,i),[],[],dsHz);
end

Pave = sum(P,2);

figure(1), clf
plot(F,10*log10(Pave),'b-');