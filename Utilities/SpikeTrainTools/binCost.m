function cost = binCost(delta,pointSumSpikes,n)
% cost function from Shimazaki & Shinomoto Neural Computation (2007)
% minimize to optimize bin size
% delta=bin size, n=no. trials
% pointSumSpikes is a 1 x (data points) vector, basically a frequency count
%   of spikes for the smallest bin size (set by sampling frequency)

delta=round(delta);
noBins = floor(length(pointSumSpikes)/delta);
binSpikes=zeros(1,noBins);
for i=1:noBins
    binSpikes(i)=sum(pointSumSpikes((i-1)*delta+1:i*delta));
end
k = mean(binSpikes);
v = var(binSpikes);

cost = (2*k-v)/((n*delta)^2);

end