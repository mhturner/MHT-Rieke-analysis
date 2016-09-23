function Xfilt = bandPassFilter(X,low,high,SampleInterval)
%this is not really correct
Xfilt = edu.washington.riekelab.turner.utils.lowPassFilter(edu.washington.riekelab.turner.utils.highPassFilter(X,low,SampleInterval),...
    high,SampleInterval);
