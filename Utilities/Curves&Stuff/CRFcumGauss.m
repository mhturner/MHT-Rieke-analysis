function res = CRFcumGauss(contrast,alphaScale,betaSens,gammaXoff,epsilonYoff)

    res = alphaScale*normcdf(betaSens.*contrast + gammaXoff,0,1)+epsilonYoff;

end