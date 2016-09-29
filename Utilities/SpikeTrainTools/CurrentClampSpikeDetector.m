function [SpikeTimes, SpikeAmplitudes] = CurrentClampSpikeDetector(DataMatrix,varargin)
% CurrentClampSpikeDetector detects spikes in current-clamp recordings
%       Pulls indices for peaks above some threshold
%       good for spikelets or intracellular spikes
%       just choose threshold high enough s.t. for each threshold crossing there's
%       only one peak
%   [SpikeTimes, SpikeAmplitudes] = CurrentClampSpikeDetector(DataMatrix,varargin)
%   RETURNS
%       SpikeTimes: In datapoints. Cell array.  Or array if just one trial;
%       SpikeAmplitudes: Cell array.
%   REQUIRED INPUTS
%       DataMatrix: Each row is a trial
%   OPTIONAL ARGUMENTS
%       Threshold: (-20) (mV)
%       CheckDetection: (false) (logical) Plots some stuff
%       SampleRate: (1e4) (Hz)
%       SearchWindow; (1.5e-3) (sec) To look for peak after threshold cross
%   MHT 9.29.2016 - Ported over from personal version. Origional: 2.16.2014

ip = inputParser;
ip.addRequired('DataMatrix',@ismatrix);
addParameter(ip,'Threshold',-20,@isnumeric);
addParameter(ip,'CheckDetection',false,@islogical);
addParameter(ip,'SampleRate',1e4,@isnumeric);
addParameter(ip,'SearchWindow',1.5E-3,@isnumeric);
    
ip.parse(DataMatrix,varargin{:});
DataMatrix = ip.Results.DataMatrix;
Threshold = ip.Results.Threshold;
CheckDetection = ip.Results.CheckDetection;
SampleRate = ip.Results.SampleRate;
SearchWindow = ip.Results.SearchWindow * SampleRate; % datapoints

nTraces = size(DataMatrix,1);
SpikeTimes = cell(nTraces,1);
SpikeAmplitudes = cell(nTraces,1);

if (CheckDetection)
    figure;
    figHandle = gcf;
end

for tt = 1:nTraces
    currentTrace = DataMatrix(tt,:);
    spikesUp=getThresCross(currentTrace,Threshold,1);
    inds = [];
    for ss = 1:length(spikesUp)
        searchEnd = min(length(currentTrace),(spikesUp(ss)+SearchWindow));
        searchTrace = currentTrace((spikesUp(ss)+1):searchEnd);
        newDowns = getThresCross(searchTrace,Threshold,-1);
        if isempty(newDowns)
            continue
        end
        spikeDown = spikesUp(ss)+newDowns(1);
        [~, ind] = max(currentTrace((spikesUp(ss)+1):spikeDown));
        inds = cat(2,inds,spikesUp(ss) + ind);
    end

    if (CheckDetection)
        figure(figHandle)
        plot(currentTrace,'k')
        hold on
        plot(inds,Threshold.*ones(1,length(inds)),'rx')
        pause; clf;
    end
    SpikeTimes{tt} = inds;
    SpikeAmplitudes{tt} = currentTrace(inds);
end

end