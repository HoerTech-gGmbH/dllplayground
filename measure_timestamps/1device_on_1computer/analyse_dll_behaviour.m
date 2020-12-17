function analyse_dll_behaviour()

  % create_simulated_data();
  % dll_smoothing('normal',0);
  % dll_smoothing('outlierFar',0);
  % calc_convergence_speed(1);
  % plot_convergence_speed();
  % plot_converged_variance();
  % calc_outlier_suppression('far',0);
  % plot_outlier_suppression('near');
  % plot_outlier_suppression('far');
  plot_jump_to_target_accuracy()
end

function create_simulated_data()
  % simulate timestamps at different sampling frequencies with normally 
  % randomized error
  nSamples = 5000;
  standDev = 4e-6;
  vSrates = 47995:0.1:48005;
  vStepSizeSec = 48 ./ vSrates;
  % create a variable containing timestamps without error to simplify
  % analysis later
  mTimestampsClean = zeros(nSamples,length(vStepSizeSec));
  mTimestamps = zeros(nSamples,length(vStepSizeSec));
  for idxFs = 1:length(vStepSizeSec)
    mTimestampsClean(:,idxFs) = (1:vStepSizeSec(idxFs): ...
                               ((nSamples-1)*vStepSizeSec(idxFs)+1))';
    mTimestamps(:,idxFs) = mTimestampsClean(:,idxFs) + randn(1,nSamples)' * ...
                                                       standDev;
    % create timestamps with outliers that are far from each other
    mTimestampsOutlierFar(:,idxFs) = mTimestamps(:,idxFs);
    for idx2 = 200:200:nSamples
      mTimestampsOutlierFar(idx2,idxFs) = ...
        mTimestampsOutlierFar(idx2,idxFs) + 0.001;
    end
    % create timestamps with outliers that are near to each other
    mTimestampsOutlierNear(:,idxFs) = mTimestamps(:,idxFs);
    for idx2 = 10:10:nSamples
      mTimestampsOutlierNear(idx2,idxFs) = ...
        mTimestampsOutlierNear(idx2,idxFs) + 0.001;
    endfor
  end
  save('-v7','simulated_data/timestamps.mat', ...
       'mTimestamps','mTimestampsClean','mTimestampsOutlierFar', ...
       'mTimestampsOutlierNear', 'vSrates');
end

function dll_smoothing(szStampType,bPlot)
  dbstop in dll_smoothing at 84;
  load('simulated_data/timestamps.mat');
  nominalSrate = 48000;
  fragsize = 48;
  % analyse bandwidths from 0.01 to 10 in log spacing
  vBandwidths = logspace(-2,1,100);
  % dim1: samples, dim2: bandwidths, dim3: srates
  mSmoothed = zeros(size(mTimestamps,1),length(vBandwidths),length(vSrates));
  if strcmp(szStampType,'outlierNear')
    mTmpTimestamps = mTimestampsOutlierNear;
  elseif strcmp(szStampType,'outlierFar')
    mTmpTimestamps = mTimestampsOutlierFar;
  else
    mTmpTimestamps = mTimestamps;
  endif
  for idxBw = 1:length(vBandwidths)
    disp(['Bandwidth ' num2str(idxBw) ' of ' ...
                      num2str(length(vBandwidths))]);
    for idxFs = 1:length(vSrates)
      if mod(idxFs,10) == 0
        disp(['Srates ' num2str(idxFs) ' of ' ...
                       num2str(length(vSrates))]);
      endif
      % perform smoothing using original dll algorithm
      mSmoothed(:,idxBw,idxFs) = dll_original(mTmpTimestamps(:,idxFs), ...
                                              nominalSrate,fragsize, ...
                                              vBandwidths(idxBw));
      % optional plotting for debugging
      if bPlot && idxBw ==50
        hFig = figure();
        hold on;
        plot(mTmpTimestamps(:,idxFs) - mTimestampsClean(:,idxFs),'ro');
        plot(mSmoothed(:,idxBw,idxFs) - mTimestampsClean(:,idxFs),'bx');
        hold off; grid on; box on;
        legend('timestamps','smoothed');
        close(hFig);
      endif
    end
  end
  if strcmp(szStampType,'outlierNear')
    mSmoothedOutlierNear = mSmoothed;
    save('-7','simulated_data/dll_smoothed_outlier_near.mat', ...
      'mSmoothedOutlierNear','vBandwidths');
  elseif strcmp(szStampType,'outlierFar')
    mSmoothedOutlierFar = mSmoothed;
    save('-7','simulated_data/dll_smoothed_outlier_far.mat', ...
      'mSmoothedOutlierFar','vBandwidths');
  else
    save('-7','simulated_data/dll_smoothed.mat','mSmoothed','vBandwidths');
  end
end

function calc_convergence_speed(bPlot)
  dbstop in calc_convergence_speed at 170;
  %dbstop in calc_convergence_speed at 123 if 'idxBw==30 && idxFs==43';
  load('simulated_data/timestamps.mat');
  load('simulated_data/dll_smoothed.mat');
  vBandwidths = logspace(-2,1,100);
  % almost the same procedure as in altered dll-version is used to detect
  % convergence, here, the tolerance is set a little higher because the
  % simulated data differs slightly from the real data
  div_tolerance = 0.008;
  mIdxConverg = zeros(length(vBandwidths),length(vSrates));
  for idxBw = 1:length(vBandwidths)
    disp(['Bandwidth ' num2str(idxBw) ' of ' ...
                      num2str(length(vBandwidths))]);
    for idxFs = 1:length(vSrates)
      % find indices that satisfy convergence criterium
      vConv = find(abs(mSmoothed(:,idxBw,idxFs) - ...
                  mTimestampsClean(:,idxFs)) < ...
                 div_tolerance * (mTimestampsClean(2,idxFs) - ...
                                  mTimestampsClean(1,idxFs)));
      % if no convergence happend (yet) say it converged at the last
      % timestamp to have a value
      if isempty(vConv)
        mIdxConverg(idxBw,idxFs) = size(mTimestamps,1);
        % since there are no changes, the smoothed stamps are expected
        % to converge and not diverge after that, that is why to be
        % called converged the last sample must satisfy convergence
        % criterium
      elseif vConv(end) == size(mTimestamps,1)
        diffConvIdx = diff(vConv);
        % after convergence all following samples are expected to be
        % converged, so the difference in indices must always be one
        % if the difference is higher it means that it is not converged
        % yet
        idxNotConv = find(diffConvIdx>1);
        if isempty(idxNotConv)
          idxConv = vConv(find(diffConvIdx==1));
        else
          idxConv = vConv(idxNotConv(end)+1);
        end
        if any(diffConvIdx(idxConv:end) ~= 1)
          error(['funny convergence at bw: ' num2str(idxBw) ...
                                    ', fs: ' num2str(idxFs)]);
        else
          mIdxConverg(idxBw,idxFs) = idxConv(1);
        end
      else
        mIdxConverg(idxBw,idxFs) = size(mTimestamps,1);
      end
      % optional plot for debugging
      if bPlot && idxBw == 100% && idxFs > 40 && idxFs < 60
        hFig = figure();
        hold on;
        plot(mTimestamps(:,idxFs)' - mTimestampsClean(:,idxFs)', ...
             'color',[.5 .5 .5],'marker','d','linestyle','-');
        plot(mSmoothed(:,idxBw,idxFs)' - mTimestampsClean(:,idxFs)', ...
             'color','blue','marker','x','linestyle','-');
        plot(mIdxConverg(idxBw,idxFs), ...
             mSmoothed(mIdxConverg(idxBw,idxFs),idxBw,idxFs) -
             mTimestampsClean(mIdxConverg(idxBw,idxFs),idxFs), ...
             'color','red','marker','o');
        plot(ones(1,size(mTimestampsClean,1)) .* div_tolerance .* ...
            (mTimestampsClean(2,idxFs) - mTimestampsClean(1,idxFs)), ...
             'color','black');
        plot(ones(1,size(mTimestampsClean,1)) .* -div_tolerance .* ...
            (mTimestampsClean(2,idxFs) - mTimestampsClean(1,idxFs)), ...
             'color','black');
        hold off;
        legend('smoothed','stamps','point of conv','tolerance');
        close(hFig);
      end
    end
  end
  save('-7','simulated_data/converg_speed.mat','mIdxConverg');
end

function plot_convergence_speed(plot_single_bandwidth)
  load('simulated_data/timestamps.mat');
  load('simulated_data/converg_speed.mat');
  vBandwidths = logspace(-2,1,100);
  hFig = figure();
  surf(vSrates,vBandwidths,mIdxConverg,'edgecolor','none');
  view(2);
  set(get(hFig,'currentaxes'),'yscale','log');
  axis tight;
  zlim([0 5000]);
  colorbar();
  xlabel('Actual FS [Hz]');
  ylabel('DLL Bandwidth [ ]');
  title('Block No. of Convergence for nominal FS = 48kHz');
  saveas(hFig,'plots/conv_speed','pdf');
end

function plot_converged_variance()
  % plot the variance of smoothed timestamps after they have converged
  % in order to assess if a higher bandwidth would mean higher
  % fluctuation after convergence
  load('simulated_data/timestamps.mat');
  load('simulated_data/dll_smoothed.mat');
  load('simulated_data/converg_speed.mat');
  vBandwidths = logspace(-2,1,100);
  mVars = zeros(length(vBandwidths),length(vSrates));
  for idxBw = 1:length(vBandwidths)
    for idxFs = 1:length(vSrates)
        mVars(idxBw,idxFs) = var(mSmoothed(mIdxConverg(idxBw,idxFs):end, ...
                                 idxBw, idxFs));
    endfor
  endfor
  hFig = figure();
  surf(vSrates,vBandwidths,mVars,'edgecolor','none');
  view(2);
  set(get(hFig,'currentaxes'),'yscale','log');
  axis tight;
  colorbar();
  xlabel('Actual FS [Hz]');
  ylabel('DLL Bandwidth [ ]');
  title('Variance after Convergence for nominal FS = 48kHz');
  saveas(hFig,'plots/variance_postconv','pdf');
end

function calc_outlier_suppression(szNearOrFar,bPlot)
  dbstop in calc_outlier_suppression at 271;
  load('simulated_data/timestamps.mat');
  load(['simulated_data/dll_smoothed_outlier_' szNearOrFar '.mat']);
  if strcmp(szNearOrFar,'far')
    mTimestampsOutlier = mTimestampsOutlierFar;
    mSmoothedOutlier = mSmoothedOutlierFar;
  elseif strcmp(szNearOrFar,'near')
    mTimestampsOutlier = mTimestampsOutlierNear;
    mSmoothedOutlier = mSmoothedOutlierNear;
  else
    error('Check your variable szNearOrFar, dude!');
  endif
  % calculate position of outliers
  vIdxOutlier = find((mTimestampsOutlier(:,1) - ...
                      mTimestampsClean(:,1)) > 0.0001);
  mOutlierSuppression = zeros(length(vIdxOutlier)-1, ...
                              length(vBandwidths), ...
                              length(vSrates));
  for idxBw = 1:length(vBandwidths)
    for idxFs = 1:length(vSrates)
      mSmoothedDiff = diff(mSmoothedOutlier(:,idxBw,idxFs));
      mTimestampsDiff = diff(mTimestampsOutlier(:,idxFs));
      % the diff vector has the jump one index earlier that's why
      % mTimestampsDiff takes vIdxOutlier-1, in mSmoothedDiff this is
      % compensated by the fact that the smoothed graph reacts one index
      % later on outliers
      mOutlierSuppression(:,idxBw,idxFs) = ...
        mSmoothedDiff(vIdxOutlier(1:end-1)) ./ ...
        mTimestampsDiff(vIdxOutlier(1:end-1)-1);
      if bPlot && idxFs == 40
        hFig = figure();
        subplot(2,1,1);
        hold on;
        plot(mSmoothedDiff,'bx');
        plot(mTimestampsDiff,'ro');
        title('diff(Stamps)');
        hold off;
        grid on;
        box on;
        legend('smoothed','timestamps');
        subplot(2,1,2);
        hold on;
        plot(mSmoothedOutlier(:,idxBw,idxFs)-mTimestampsClean(:,idxFs),'bx');
        plot(mTimestampsOutlier(:,idxFs)-mTimestampsClean(:,idxFs),'ro');
        title('Stamps');
        hold off;
        grid on;
        box on;
        legend('smoothed','timestamps');
        close(hFig);
      endif
    endfor
  endfor
  if strcmp(szNearOrFar,'far')
    mOutlierSuppressionFar = mOutlierSuppression;
    save('-v7',['simulated_data/outlier_suppression_' szNearOrFar '.mat'], ...
       'mOutlierSuppressionFar','vSrates','vBandwidths');
  elseif strcmp(szNearOrFar,'near')
    mOutlierSuppressionNear = mOutlierSuppression;
    save('-v7',['simulated_data/outlier_suppression_' szNearOrFar '.mat'], ...
       'mOutlierSuppressionNear','vSrates','vBandwidths');
  else
    error('Check your variable szNearOrFar, dude!');
  endif
end

function plot_outlier_suppression(szNearOrFar)
  load(['simulated_data/outlier_suppression_' szNearOrFar '.mat']);
  if strcmp(szNearOrFar,'far')
    mOutlierSuppression = mOutlierSuppressionFar;
  elseif strcmp(szNearOrFar,'near')
    mOutlierSuppression = mOutlierSuppressionNear;
  else
    error('Check your variable szNearOrFar, dude!');
  endif
  mMeanSupp = zeros(length(vBandwidths),length(vSrates));
  mVarSupp = zeros(length(vBandwidths),length(vSrates));
  for idxBw = 1:length(vBandwidths)
    for idxFs = 1:length(vSrates)
      mMeanSupp(idxBw,idxFs) = mean(mOutlierSuppression(:,idxBw,idxFs));
      mVarSupp(idxBw,idxFs) = var(mOutlierSuppression(:,idxBw,idxFs));
    endfor
  endfor

  hFigMean = figure();
  surf(vSrates,vBandwidths,mMeanSupp,'edgecolor','none');
  view(2);
  set(get(hFigMean,'currentaxes'),'yscale','log');
  axis tight;
  colorbar();
  xlabel('Actual FS [Hz]');
  ylabel('DLL Bandwidth [ ]');
  title(['Average Outlier Suppression (' szNearOrFar ...
    ') for nominal FS = 48kHz']);
  %saveas(hFigMean,'plots/outlier_suppression_mean','pdf');

  hFigVar = figure();
  surf(vSrates,vBandwidths,mVarSupp,'edgecolor','none');
  view(2);
  set(get(hFigVar,'currentaxes'),'yscale','log');
  axis tight;
  colorbar();
  xlabel('Actual FS [Hz]');
  ylabel('DLL Bandwidth [ ]');
  title(['Variance of Outlier Suppression (' szNearOrFar ...
    ') for nominal FS = 48kHz']);
  %saveas(hFigVar,'plots/outlier_suppression_var','pdf');
end

function plot_jump_to_target_accuracy()
  load('simulated_data/timestamps.mat');
  load('simulated_data/dll_smoothed.mat');
  load('simulated_data/converg_speed.mat');
  vBandwidths = logspace(-2,1,100);
  nMedianValues = 10;
  fragsize = 48;
  vEstimFsError = zeros(length(vBandwidths),length(vSrates));
  for idxBw = 1:length(vBandwidths)
    for idxFs = 1:length(vSrates)
      if mIdxConverg(idxBw,idxFs) < size(mTimestamps,1)
        vEstimFsError(idxBw,idxFs) = fragsize / abs(median(diff( ...
          mSmoothed(end-(nMedianValues-1):end,idxBw,idxFs)))) - vSrates(idxFs);
      else
        vEstimFsError(idxBw,idxFs) = NaN;
      endif
    endfor
  endfor
  hFig = figure();
  surf(vSrates,vBandwidths,vEstimFsError,'edgecolor','none');
  set(get(hFig,'currentaxes'),'yscale','log');
  view(2);
  axis tight;
  colorbar;
  xlabel('Actual FS [Hz]');
  ylabel('DLL Bandwidth [ ]');
  title('Difference of estimated and actual FS in Hz');
  saveas(hFig,'plots/estim_fs_error','pdf');
endfunction
