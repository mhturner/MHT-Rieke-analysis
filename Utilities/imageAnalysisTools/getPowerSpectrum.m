function res = getPowerSpectrum(image,pixelsPerDegree)
    %takes a square image as input - Bruno Olshausen's rotavg.m needs
    %square matrix
    %pixel size = pixels per degree, to give f as cycles/degree
    imf = fftshift(fft2(image)); %convert to frequency domain and shift DC to zero
    imp = abs(imf).^2; %power spectrum
    res.p = rotavg(imp); %rotational average
    
    res.phase = atan(imag(imf)./real(imf));
    
    freqNy=pixelsPerDegree/2; %nyquist frequency

    res.f=(freqNy*linspace(0,1,size(image,1)/2+1))'; %spatial frequencies in cycles/degree
    
    
    res.conjugate=imp;
end