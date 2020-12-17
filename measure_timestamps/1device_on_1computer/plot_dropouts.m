function plot_dropouts(mFragtimes_ms,mDropouts,cLegend)
  % 1col = 1 sound device
  hFig = figure();
  plot(mFragtimes_ms,mDropouts);
  xlabel('Block length [ms]');
  ylabel('No. of Dropouts [ ]');
  title('Dropouts over Block lengths');
  legend(cLegend);
  saveas(hFig,'plots/dropouts','pdf');
