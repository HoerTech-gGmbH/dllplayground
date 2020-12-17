function [smoothed] = dll_original(input, srate, fragsize, bandwidth)
  % input must be column vector
  F = srate/fragsize;
  w = 2*pi*bandwidth/F;
  a = 0;
  b = sqrt(2)*w;
  c = w.^2;
  times = input;
  tper = 1/F;
  e2=tper;
  t0 = times(1);
  t1 = t0 + e2;
  smoothed = [];
  smoothed = [smoothed;t0];
  for time = times(2:end)'
    % smoothing
    e = time - t1;
    t0 = t1;
    smoothed = [smoothed;t0];
    t1 = t1 + b*e + e2;
    e2 = e2 + c*e;
  end
end
