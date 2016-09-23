function res = CRFcumGauss(contrast,alphaScale,betaSens,gammaXoff,epsilonYoff)
    % res = CRFcumGauss(contrast,alphaScale,betaSens,gammaXoff,epsilonYoff)
    % Modified cumulative gaussian function, to fit a smooth curve to
    % contrast-response data
    %   alphaScale is an absolute scaling factor in y
    %   betaSens determines the sensitivity / slope
    %   gammaXoff is an offset along the x axis (contrast)
    %   epsilonYoff is an offset along the y axis (response)

    res = alphaScale*normcdf(betaSens.*contrast + gammaXoff,0,1)+epsilonYoff;

end