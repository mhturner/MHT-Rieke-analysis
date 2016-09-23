function Xfilt = highPassFilter(X,F,SampleInterval)
% Xfilt = highPassFilter(X,F,SampleInterval)
    % F is in Hz
    % SampleInterval is in seconds
    % X is a vector or a matrix of row vectors
    L = size(X,2);
    if L == 1 %flip if given a column vector
        X=X'; 
        L = size(X,2);
    end

    FreqStepSize = 1/(SampleInterval * L);
    FreqKeepPts = round(F / FreqStepSize);

    FFTData = fft(X, [], 2);
    FFTData(:,1:FreqKeepPts) = 0;
    FFTData(end-FreqKeepPts:end) = 0;
    Xfilt = real(ifft(FFTData, [], 2));
end