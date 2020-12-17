function [smoothed] = dll(input,vDropouts, srate, fragsize, vBandwidth)
  % vBandwidth shall be composed of two values, the first for fast
  % adaption, the second for slow adaption
  F = srate/fragsize;
  w = 2*pi*vBandwidth/F;
  a = 0;
  vB = sqrt(2)*w;
  vC = w.^2;

  times = input;

  tper = 1/F;
  e2=tper;
  t0 = times(1);
  t1 = t0 + e2;
  smoothed = [];
  smoothed = [smoothed;t0];
  % remember the last memLength timestamps
  memLength = 10;
  % vector for remembering timestamps
  stampMem = [times(1)];
  % tolerate jumps from one to the next stamp if they are
  % smaller than the median distance of the last memLength stamps
  % times jump_tolerance
  jump_tolerance = 1.02;
  % the smoothed curve is not considered to diverge from the raw
  % timestamps unless the median difference of the last memLength
  % smoothed values and the last memLength raw timestamps is greater
  % than the median distance of the last memLength raw timestamps
  % times div_tolerance
  div_tolerance = 0.005;
  % bool indicating if diverged
  bDiverg = 0;
  % bool indicating if outlier
  bOutlier = 0;
  % bool indicating verbose output for debugging
  bVerbose = 0;
  for time = times(2:end)'
    idx = find(time==times);
    if bVerbose 
      disp(idx);
    end
    if vDropouts(idx)
      % in case of dropout: fake the past by adding the lost time minus the 
      % median step size
      % do not assign new values to b and c, instead take the values of the 
      % previous iteration
      tempLastStampMem = stampMem(end);
      stampMem = stampMem + (time - tempLastStampMem - median(diff(stampMem)));
      t1 = t1 + (time - tempLastStampMem - median(diff(stampMem)));
      if ~exist('b','var')
        % in case there are no values assigned to b and c use fast adaption
        b = vB(1);
        c = vC(1);
      endif
    else
      % fast adaption at the beginning to quickly adapt to timestamps
      if length(stampMem) < memLength
        b = vB(1);
        c = vC(1);
      else
        % no outlier, but smoothed diverges from stamps
        % divergence of smoothed from raw timestamps is asserted by comparing
        % the difference of smoothed and raw timestamps to the median step
        % size times div_tolerance
        if (abs(median(smoothed(end-memLength+1:end) - stampMem)) > ...
            div_tolerance * abs(median(diff(stampMem))))
          bDiverg = 1;
        end
        % if big jump in stamps is detected
        % if outlier detected, stop adaption for one cycle
        % outlier is asserted if distance of last to current timestamp is
        % greater than jump_tolerance times the median distance between the
        % last memLength timestamps
        if (abs(time - stampMem(end)) > ...
            jump_tolerance * abs(median(diff(stampMem))))
          bOutlier = 1;
        end
        % bDiverg and bOutlier might both be true, use fast adaption if
        % only divergence is true to get back on track quickly
        if bDiverg && ~bOutlier
          b = vB(1);
          c = vC(1);
          % if an outlier is detected and smoothed does not diverge skip
          % this adaption step and calculate the new smoothed value using
          % the last smoothed value and its distance to the smoothed value
          % before the last
        elseif bOutlier
          new_smoothed = 2*smoothed(end) - smoothed(end-1);
          smoothed = [smoothed; new_smoothed];
          % calculate smoothing parameters for next cycle (take e from last cycle)
          t1 = t1 + vB(2)*e + e2;
          e2 = e2 + vC(2)*e;
          stampMem = [stampMem; time];
          if length(stampMem) > memLength
            stampMem = stampMem(end-memLength+1:end);
          end
          bOutlier = 0;
          continue;
        else
          % no outlier and smoothed is in tolerable distance from
          % stamps
          b = vB(2);
          c = vC(2);
        end
      end
    end

    stampMem = [stampMem; time];
    if length(stampMem) > memLength
      stampMem = stampMem(end-memLength+1:end);
    end

    if bVerbose
      bIdx=find(b==vB)
      cIdx=find(c==vC)
      bDiverg
      bOutlier
    end
    bDiverg = 0;
    % smoothing
    e = time - t1;
    t0 = t1;
    smoothed = [smoothed;t0];
    t1 = t1 + b*e + e2;
    e2 = e2 + c*e;
  end
