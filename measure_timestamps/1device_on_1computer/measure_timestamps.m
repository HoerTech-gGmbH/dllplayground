function [dropouts_onboard, dropouts_scarlett] = ...
         measure_timestamps(fragsize,idx_scarlett)
addpath('../../mha/tools/mfiles/');
setenv('FRAGSIZE',num2str(fragsize));

mha_onboard = mha_start;
mha_set(mha_onboard,'fragsize',fragsize);
mha_query(mha_onboard,'','read:get_stamps_onboard.cfg');
dropouts_onboard = str2num(mha_query(mha_onboard, ...
                                     'io.alsa_start_counter', ...
                                     'val')) - 1;
mha_set(mha_onboard,'cmd','quit');

mha_scarlett = mha_start;
mha_set(mha_scarlett,'fragsize',fragsize);
mha_set(mha_scarlett,'srate',48000);
mha_set(mha_scarlett,'nchannels_in',2);
mha_set(mha_scarlett,'iolib','MHAIOalsa');
mha_set(mha_scarlett,'io.in.device',idx_scarlett);
mha_set(mha_scarlett,'io.out.device',idx_scarlett);
mha_query(mha_scarlett,'','read:get_stamps_scarlett.cfg');
dropouts_scarlett = str2num(mha_query(mha_scarlett, ...
                                      'io.alsa_start_counter', ...
                                      'val')) - 1;
mha_set(mha_scarlett,'cmd','quit');
