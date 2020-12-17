function plot_dlls()
  close all;
  pkg load optim;
  fragsize = 480;
  fs = 48000;
  load(['data/onboard' num2str(fragsize) '.mat']);
  if ~exist('vDropouts','var')
    vDropouts = zeros(length(timestamper),1);
  endif
  vStampsNorm = timestamper - timestamper(1);
  vXRegr = [ones(length(vStampsNorm),1),(1:length(vStampsNorm))'];
  p = LinearRegression(vXRegr,vStampsNorm);
  vStampsRegr = vXRegr * p;
  vBandwidths = [10,1];
  plot_bound = 500;

  vSmoothed = dll(timestamper,vDropouts,fs,fragsize,vBandwidths);
  vSmoothNorm = vSmoothed - vSmoothed(1);
  figure(1);
  subplot(2,1,1);
  hold all;
  if plot_bound
    plot(vStampsNorm(1:plot_bound) - vStampsRegr(1:plot_bound),'marker','x');
    plot(vSmoothNorm(1:plot_bound) - vStampsRegr(1:plot_bound),'marker','o');
  else
    plot(vStampsNorm - vStampsRegr,'marker','x');
    plot(vSmoothNorm - vStampsRegr,'marker','o');
  end
  % plot(vStampsNorm - vSmoothNorm);
  legend('timestamps','smoothed');
  title(['Difference to LinearRegression(timestamps),' ... 
         ' Bandwidth = ' num2str(vBandwidths)]);
  grid on;
  
  subplot(2,1,2);
  hold all;
  if plot_bound
    plot(diff(vStampsNorm(1:plot_bound)),'marker','x');
    plot(diff(vSmoothNorm(1:plot_bound)),'marker','o');
  else
    plot(diff(vStampsNorm),'marker','x');
    plot(diff(vSmoothNorm),'marker','o');
  end
  legend('timestamps','smoothed');
  title('Difference of Elements');
  grid on;
  
  var(vSmoothNorm(10:end) - vStampsRegr(10:end))
%  figure(2);
%  hold all;
%  plot(vStampsNorm);
%  plot(vSmoothNorm);
%  plot(vStampsRegr);
%  legend('timestamps','smoothed','regression');
%  title(['Bandwidth = ' num2str(vBandwidths(idx))]);
%  grid on;
  end
