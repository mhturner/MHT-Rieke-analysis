function [SpikeTimes, SpikeAmplitudes, RefractoryViolations] = SpikeDetector(DataMatrix,varargin)
%SpikeDetector detects spikes in an extracellular / cell attached recording
%   [SpikeTimes, SpikeAmplitudes, RefractoryViolations] = SpikeDetector(dataMatrix,varargin)
%   RETURNS
%       SpikeTimes: In datapoints. Cell array. Or array if just one trial;
%       SpikeAmplitudes: Cell array.
%       RefractoryViolations: Indices of SpikeTimes that had refractory
%           violations. Cell array.
%   REQUIRED INPUTS
%       DataMatrix: Each row is a trial
%   OPTIONAL ARGUMENTS
%       CheckDetection: (false) (logical) Plots clustering information for
%           each trace
%       SampleRate: (1e4) (Hz)
%       RefractoryPeriod: (1.5e-3) (sec)
%       SearchWindow; (1.2e-3) (sec) To look for rebounds. Search interval 
%           is (peak time +/- SearchWindow/2)
%       RemoveRefractoryViolations: (true) (logical) removes refractory violations from
%       spike times and spike amplitudes
%       thresholdSpikeFactor: (10) (numeric, a.u.) how many noise st-devs
%       above zero must spike amplitudes be? Uses mean cluster amplitude to
%       detect "no spike" trials (doesn't filter out individual spikes this
%       way). Be very careful of setting this too high.
%   
%   Clusters peak waveforms into 2 clusters using k-means. Based on three
%   quantities about each spike waveform: amplitude of the peak, amlitude
%   of a rebound on the right and left.
%   MHT 9.23.2016 - Ported over from personal version
%   MHT 1.25.2017 - Added option to remove refractory violation spike times

ip = inputParser;
ip.addRequired('DataMatrix',@ismatrix);
addParameter(ip,'CheckDetection',false,@islogical);
addParameter(ip,'SampleRate',1e4,@isnumeric);
addParameter(ip,'RefractoryPeriod',1.5E-3,@isnumeric);
addParameter(ip,'SearchWindow',1.2E-3,@isnumeric);
addParameter(ip,'RemoveRefractoryViolations',true,@islogical);
addParameter(ip,'thresholdSpikeFactor',10,@isnumeric); 

    
ip.parse(DataMatrix,varargin{:});
DataMatrix = ip.Results.DataMatrix;
CheckDetection = ip.Results.CheckDetection;
SampleRate = ip.Results.SampleRate;
RefractoryPeriod = ip.Results.RefractoryPeriod * SampleRate; % datapoints
SearchWindow = ip.Results.SearchWindow * SampleRate; % datapoints
RemoveRefractoryViolations = ip.Results.RemoveRefractoryViolations;
thresholdSpikeFactor = ip.Results.thresholdSpikeFactor;

CutoffFrequency = 500; %Hz
DataMatrix = highPassFilter(DataMatrix,CutoffFrequency,1/SampleRate);

nTraces = size(DataMatrix,1);
SpikeTimes = cell(nTraces,1);
SpikeAmplitudes = cell(nTraces,1);
RefractoryViolations = cell(nTraces,1);

if (CheckDetection)
    figHandle = figure(40);
end

for tt=1:nTraces
    currentTrace = DataMatrix(tt,:);
    if abs(max(currentTrace)) > abs(min(currentTrace)) % flip it over, big peaks down
        currentTrace = -currentTrace;
    end

    % get peaks
    [peakAmplitudes, peakTimes] = getPeaks(currentTrace,-1); % -1 for negative peaks
    peakTimes = peakTimes(peakAmplitudes<0); % only negative deflections
    peakAmplitudes = abs(peakAmplitudes(peakAmplitudes<0)); % only negative deflections
    
    % get rebounds on either side of each peak
    rebound = getRebounds(peakTimes,currentTrace,SearchWindow);
    
    % cluster spikes
    clusteringData = [peakAmplitudes', rebound.Left', rebound.Right'];
    startMatrix = [median(peakAmplitudes) median(rebound.Left) median(rebound.Right);...
        max(peakAmplitudes) max(rebound.Left) max(rebound.Right)];
    clusteringOptions = statset('MaxIter',10000);
    try %traces with no spikes sometimes throw an "empty cluster" error in kmeans
        [clusterIndex, centroidAmplitudes] = kmeans(clusteringData, 2,...
            'start',startMatrix,'Options',clusteringOptions);
    catch err
        if strcmp(err.identifier,'stats:kmeans:EmptyCluster')
            %initialize clusters using random sampling instead
            [clusterIndex, centroidAmplitudes] = kmeans(clusteringData,2,'start','sample','Options',clusteringOptions);
        end
    end
    [~,spikeClusterIndex] = max(centroidAmplitudes(:,1)); %find cluster with largest peak amplitude
    nonspikeClusterIndex = setdiff([1 2],spikeClusterIndex); %nonspike cluster index
    spikeIndex_logical = (clusterIndex == spikeClusterIndex); %spike_ind_log is logical, length of peaks
    
    % get spike times and amplitudes
    SpikeTimes{tt} = peakTimes(spikeIndex_logical);
    SpikeAmplitudes{tt} = peakAmplitudes(spikeIndex_logical);
    nonspikeAmplitudes = peakAmplitudes(~spikeIndex_logical);
    
    %check for no spikes trace
    %how many st-devs greater is spike peak than noise peak?
    sigF = (mean(SpikeAmplitudes{tt}) - mean(nonspikeAmplitudes)) / std(nonspikeAmplitudes);
    
    if sigF < thresholdSpikeFactor; %no spikes
        SpikeTimes{tt} = [];
        SpikeAmplitudes{tt} = []; 
        RefractoryViolations{tt} = [];
        disp(['Trial '  num2str(tt) ': no spikes. SF = ',num2str(sigF)]);

% %         figHandle = figure(40);
% %         plotClusteringData();

        if (CheckDetection)
            plotClusteringData();
        end
        continue
    end
    
    % check for refractory violations
    RefractoryViolations{tt} = find(diff(SpikeTimes{tt}) < RefractoryPeriod) + 1;
    ref_violations = length(RefractoryViolations{tt});
    if ref_violations > 0
% %         figHandle = figure(40);
% %         plotClusteringData()
        if (RemoveRefractoryViolations)
            disp(['Trial '  num2str(tt) ': ' num2str(ref_violations) ' refractory violations removed']);
        else
            disp(['Trial '  num2str(tt) ': ' num2str(ref_violations) ' refractory violations remain']);
        end
    end

    if (CheckDetection)
        plotClusteringData()
    end
end
if (RemoveRefractoryViolations)
    for tt = 1:length(SpikeTimes)
        SpikeTimes{tt}(RefractoryViolations{tt}) = [];
        SpikeAmplitudes{tt}(RefractoryViolations{tt}) = [];
    end
end

if length(SpikeTimes) == 1 %return vector not cell array if only 1 trial
    SpikeTimes = SpikeTimes{1};
    SpikeAmplitudes = SpikeAmplitudes{1};    
    RefractoryViolations = RefractoryViolations{1};
end

function plotClusteringData()
    figure(figHandle)
    subplot(1,2,1); hold on;
    plot3(peakAmplitudes(clusterIndex==spikeClusterIndex),...
        rebound.Left(clusterIndex==spikeClusterIndex),...
        rebound.Right(clusterIndex==spikeClusterIndex),'ro')
    plot3(peakAmplitudes(clusterIndex==nonspikeClusterIndex),...
        rebound.Left(clusterIndex==nonspikeClusterIndex),...
        rebound.Right(clusterIndex==nonspikeClusterIndex),'ko')
    xlabel('Peak Amplitude'); ylabel('L rebound'); zlabel('R rebound')
    view([8 36])
    subplot(1,2,2)
    plot(currentTrace,'k'); hold on;
    plot(SpikeTimes{tt}, ...
        currentTrace(SpikeTimes{tt}),'rx')
    plot(SpikeTimes{tt}(RefractoryViolations{tt}), ...
        currentTrace(SpikeTimes{tt}(RefractoryViolations{tt})),'go')
    title(['SpikeFactor = ', num2str(sigF)])
    drawnow;
    pause(); clf;
end

end
