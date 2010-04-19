function epochs = importScoredFFT(fname)
% epochs = importScoredFFT(fname)
% Imports data from SleepSign export using FFT->Text Output->Continuous
%   and constructs a struct with timestamped per-epoch scoring labels and 
%   power spectra. Call with no argument to choose the file using a dialog.

if(~exist('fname','var'))
    [file path] = uigetfile({'*.txt;*.dat', 'Text Files'}, ...
        'Choose a SleepSign FFT Continuous Export File');
    fname = strcat(path,file);
end

try
    rawdata = importdata(fname);
    fid = fopen(fname);
catch e
    error('Error opening file: %s', e.message);
    return
end

epochs = [];

% search for the first line containing 'Time'
pattern = 'Time';
linenum = 0;
while(1)
   linenum = linenum+1;
   l = fgetl(fid);
   if(l == -1)
       error('Could not find frequency band info in file.');
   end
   inds = strfind(l,pattern);
   if(~isempty(inds));
       break;
   end 
end

linenum = linenum+1; % linenum is now the first usable line of data
l = l(inds(1)+length(pattern):end); % strip off prefix of line
epochs.freqbands = sscanf(l,'%fHz'); % parse out frequency bands in Hz
epochs.idx = cellfun(@str2num,{rawdata.textdata{linenum:end,1}}); % epoch indices
epochs.score = {rawdata.textdata{linenum:end,2}}; % epoch score strings
epochs.timestr = {rawdata.textdata{linenum:end,3}}; % epoch time stamps
epochs.fft = rawdata.data; % epoch power by freq band 

% convert time representations into a more usable format
starttime = datevec(epochs.timestr(1));
epochs.timevec = cellfun(@datevec, epochs.timestr,'UniformOutput',false);
epochs.sec = cellfun(@(tvec) etime(tvec,starttime), epochs.timevec);
