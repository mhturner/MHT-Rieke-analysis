function res = getF1F2Power(signal,modulationFrequency,samplingRate,plotFigNumber)
    if nargin<2
       error('Needs signal and modulation frequency') 
    elseif nargin<3
        samplingRate = 1e4; %10 kHz default
        plotFigNumber = []; %no plot default
    elseif nargin<4
        plotFigNumber = []; %no plot default
    end
    
    sf = samplingRate; %sampling rate, Hz
    n = length(signal); %length of signal, datapoints
    L = n / sf;
    tDim = (1:n)./sf;

    k = (1/L)*[0:(n/2-1) -n/2:-1]; %fourier domain, Hz
    fs = fftshift(k); %shifted to intuitive ordering
    spec = fftshift(fft(signal./n)); %signal scaled by length
    %one-sided spectrum
    f = fs(n/2+1:end);
    X = 2.*abs(spec(n/2+1:end)); %amplitude spectrum, double b/c of symmetry about zero

    [val F1ind] = min(abs(f-modulationFrequency));
    [val F2ind] = min(abs(f-2*modulationFrequency));
    
    F1amplitude = X(F1ind); %fourier amplitude: pA or spikes/sec
    F2amplitude = X(F2ind);
    
    F1power = F1amplitude^2; %power: pA^2 for current rec, (spikes/sec)^2 for spike rate
    F2power = F2amplitude^2; 
    
    if ~isempty(plotFigNumber)
        eval(['figure(',num2str(plotFigNumber),')'])
        subplot(2,1,1)
        plot(tDim,signal,'k')
        subplot(2,1,2)
        plot(f,X,'k-o'); hold on
        plot(f(F1ind),X(F1ind),'bx')
        plot(f(F2ind),X(F2ind),'rx')
        xlim([f(2) 5*modulationFrequency]) 
        xlabel('Freq (Hz)')
        ylabel('Amp')
    end
    
    res.F1amplitude = F1amplitude;
    res.F2amplitude = F2amplitude;

    res.F1power = F1power;
    res.F2power = F2power;


end