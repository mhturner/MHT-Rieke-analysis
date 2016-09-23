function results = SpikeDetector(D,checkDetectionFlag,epochNo,specialFlag)
% results = SpikeDetector(D,checkDetectionFlag,epochNo,specialFlag)
    % MHT last updated 1/28/15
    %   Took out some extraneous stuff
    %   Replaced old high pass filter with Debauchies(4) HP filter
    %   Now Kmeans clustering on 3 variables: peak height, and
    %   two rebound depths: one to the left and one to the right of
    %   peak. Search window = searchInterval
    %   Input
    %     -D = Response traces in matrix size [trials, epochLength]
    %   Optional parameters...
    %     -checkDetectionFlag == 1 will plot some clustering stuff to check
    %     detection
    %     -epochNo = for checkDetection figs
    %     -specialFlag usually for traces with 2 cells. give target
    %   spike direction 'upward' or 'downward' and don't use rebounds
    %   for clustering, just peak amps
    % Output: S.sp = spike times, .spikeAmps, and .violation_ind = refractory
    % violations associated with S.sp

if nargin < 2
    checkDetectionFlag = 0;
    epochNo = 0;
    specialFlag = [];
elseif nargin <3
    epochNo = 0;
    specialFlag = [];
elseif nargin<4
    specialFlag = [];
end
if isempty(checkDetectionFlag)
    checkDetectionFlag = 0;
end
% checkDetectionFlag = 0;

SampleInterval = 1E-4;
ref_period = 1.5E-3; %s
searchInterval = 1.2E-3; %s, for rebound measurement, looks in (peak_time +/- searchInterval/2)

results = [];

ref_period_points = round(ref_period./SampleInterval);
searchInterval_points = round(searchInterval./SampleInterval);

[Ntraces,~] = size(D);
Dhighpass =  DB4Filter(D,6);

sp = cell(Ntraces,1);
spikeAmps = cell(Ntraces,1);
violation_ind = cell(Ntraces,1);

for i=1:Ntraces
    trace = Dhighpass(i,:);
    if strcmp(specialFlag,'downward') 
        %do nothing, target peaks already down
    elseif strcmp(specialFlag,'upward')
        trace = -trace; %make target peaks down
    else
        if abs(max(trace)) > abs(min(trace)) %flip it over, big peaks down
            trace = -trace;
        end
    end
    
    
    %get peaks
    [peaks,peak_times] = getPeaks(trace,-1); %-1 for negative peaks
    peak_times = peak_times(peaks<0); %only negative deflections
    
    %basically another filtering step:
    %remove single sample peaks
    trace_res_even = trace(2:2:end);
    trace_res_odd = trace(1:2:end);
    [~,peak_times_res_even] = getPeaks(trace_res_even,-1);
    [~,peak_times_res_odd] = getPeaks(trace_res_odd,-1);
    peak_times_res_even = peak_times_res_even*2;
    peak_times_res_odd = 2*peak_times_res_odd-1;
    peak_times = intersect(peak_times,[peak_times_res_even,peak_times_res_odd]);
    peaks = trace(peak_times);

    %get rebounds on either side
    r = getRebounds(peak_times,trace,searchInterval_points);
    peakAmps = abs(peaks);
    
    if or(strcmp(specialFlag,'downward'),strcmp(specialFlag,'upward')) %don't use rebounds to cluster
        spikeData = peakAmps';
        startMat = [median(peakAmps);...
            max(peakAmps)];
    else
        spikeData = [peakAmps',r.Left', r.Right'];
        startMat = [median(peakAmps) median(r.Left) median(r.Right);...
            max(peakAmps) max(r.Left) max(r.Right)];
    end

    options = statset('MaxIter',10000);
    try %traces with no spikes sometimes throw an "empty cluster" error in kmeans
        [Ind,centroid_amps] = kmeans(spikeData,2,'start',startMat,'Options',options);
    catch err
        if strcmp(err.identifier,'stats:kmeans:EmptyCluster')
            %initialize clusters using random sampling instead
            [Ind,centroid_amps] = kmeans(spikeData,2,'start','sample','Options',options);
        end
    end
    [~,m_ind] = max(centroid_amps(:,1)); %find cluster with largest peak amplitude
    n_ind = find(~([1 2]==m_ind)); %nonspike cluster index
    spike_ind_log = (Ind==m_ind); %spike_ind_log is logical, length of peaks
    
    %get spike times and amps
    sp{i} = peak_times(spike_ind_log);
    spikeAmps{i} = peakAmps(spike_ind_log);
    nonSpikeAmps = peakAmps(~spike_ind_log);
    
    %check for no spikes trace
    %how many st-devs greater is spike peak than noise peak?
    sigF = (mean(spikeAmps{i}) - mean(nonSpikeAmps)) / std(nonSpikeAmps);
    
    if sigF < 5; %no spikes
        sp{i} = [];
        spikeAmps{i} = []; 
        violation_ind{i} = [];
        disp(['Epoch ', num2str(epochNo), ', Trial '  num2str(i) ': no spikes!']);
        if (checkDetectionFlag)
           figure(1);
            subplot(1,2,1)
            plot3(peakAmps(Ind==m_ind), r.Left(Ind==m_ind), r.Right(Ind==m_ind),'ro')
            hold on;
            plot3(peakAmps(Ind==n_ind), r.Left(Ind==n_ind), r.Right(Ind==n_ind),'ko')
            xlabel('PeakAmp'); ylabel('L rebound'); zlabel('R rebound')
            view([8 36])
            subplot(1,2,2)
            plot(trace,'k'); hold on;
            title([num2str(epochNo), ': No spikes!'])
            pause(1); clf;
        end
        
        continue
    end
    
    %check for violations, for warning
    violation_ind{i} = find(diff(sp{i})<ref_period_points) + 1;
    ref_violations = length(violation_ind{i});
    if ref_violations>0
        disp(['Epoch ', num2str(epochNo), ', trial '  num2str(i) ': ' num2str(ref_violations) ' refractory violations']);
    end

    if (checkDetectionFlag)
        figure(1);
        subplot(1,2,1)
        plot3(peakAmps(Ind==m_ind), r.Left(Ind==m_ind), r.Right(Ind==m_ind),'ro')
        hold on;
        plot3(peakAmps(Ind==n_ind), r.Left(Ind==n_ind), r.Right(Ind==n_ind),'ko')
        xlabel('PeakAmp'); ylabel('L rebound'); zlabel('R rebound')
        view([8 36])
        title(num2str(epochNo))
        subplot(1,2,2)
        plot(trace,'k'); hold on;
        plot(peak_times(spike_ind_log), trace(peak_times(spike_ind_log)),'rx')
        plot(sp{i}(violation_ind{i}), trace(sp{i}(violation_ind{i})),'go')
        title(['SpikeFactor = ', num2str(sigF)])
        if isempty(violation_ind{i})
            pause(0.1); clf;
        else
            pause; clf;
        end
        
    end
end

if length(sp) == 1 %return vector not cell array if only 1 trial
    sp = sp{1};
    spikeAmps = spikeAmps{1};    
    violation_ind = violation_ind{1};
end
results.sp = sp;
results.spikeAmps = spikeAmps;
results.violation_ind = violation_ind;
