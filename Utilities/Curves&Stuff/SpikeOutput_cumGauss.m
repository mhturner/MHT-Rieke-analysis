function res = SpikeOutput_cumGauss(input,alphaScale,betaSens,gammaXoff)
    % res = SpikeOutput_cumGauss(input,alphaScale,betaSens,gammaXoff)
    % Modified cumulative gaussian function, to fit a smooth curve to
    % synaptic input vs. spike output data
    %   alphaScale is an absolute scaling factor in y
    %   betaSens determines the sensitivity / slope
    %   gammaXoff is an offset along the x axis (input)
    res = alphaScale*normcdf(betaSens.*input + gammaXoff,0,1);
    
end