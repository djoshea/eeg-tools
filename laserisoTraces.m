%% generate laser and iso traces

min = epochs.sec / 60;
laser = (min > 16 & min < 32) | (min > 47 & min < 67) | (min > 116 & min < 157) | (min > 159 & min < 216);

downperiod = min > 124 & min < 164;
upperiod = min >= 164 & min < 210;
sevo = zeros(nepoch, 1);
sevo(downperiod | upperiod) = 1;
epochs.laser = logical(laser);
epochs.anesthetic = logical(sevo);