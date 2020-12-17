function multiple_fragsize_timestamps(idx_scarlett)
fs = 48000;
vFragtimes_ms = 1:20;
vFragsizes = fs/1000 .* vFragtimes_ms;
vDropouts_onboard = zeros(length(vFragsizes),1);
vDropouts_scarlett = zeros(length(vFragsizes),1);

hWBar = waitbar(0, 'prepare');

for idx = 1:length(vFragsizes)
  waitbar(idx/length(vFragsizes),hWBar, ...
          ['process ' num2str(idx) ' of ' ...
                      num2str(length(vFragsizes))]);
  pause(0.5);
  [d_onboard, d_scarlett] = ...
  measure_timestamps(vFragsizes(idx),idx_scarlett);
  vDropouts_onboard(idx) = str2num(d_onboard);
  vDropouts_scarlett(idx) = str2num(d_scarlett);
  plot_timestamps(vFragsizes(idx));
end
close(hWBar);

save('-mat4-binary','data/dropouts.mat', ...
     'vFragtimes_ms','vDropouts_onboard','vDropouts_scarlett');
mDropouts = [vDropouts_onboard, vDropouts_scarlett];
mFragtimes_ms = vFragtimes_ms' .* ones(1,2);
plot_dropouts(mFragtimes_ms,mDropouts,{'onboard','scarlett'});
