function plot_timestamps(fragsize)

onboard_data = load(['data/onboard' num2str(fragsize) '.mat']);
scarlett_data = load(['data/scarlett' num2str(fragsize) '.mat']);

fig1=figure(1);
plot(diff(onboard_data.timestamper));
title(['diff(timestamps) of onboard soundcard, fragsize ' ...
         num2str(fragsize)]);
xlabel('n^{th} processing callback');
ylabel('timestamp difference [s]');
saveas(fig1,['plots/onboard' num2str(fragsize)],'pdf');

fig2=figure(2);
plot(diff(scarlett_data.timestamper));
title(['diff(timestamps) of focusrite scarlett 2i2, fragsize ' ...
         num2str(fragsize)]);
xlabel('n^{th} processing callback');
ylabel('timestamp difference [s]');
saveas(fig2,['plots/scarlett' num2str(fragsize)],'pdf');
