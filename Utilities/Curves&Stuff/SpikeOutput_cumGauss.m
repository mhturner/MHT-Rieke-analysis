function res = SpikeOutput_cumGauss(contrast,alphaScale,betaSens,gammaXoff)

    res = alphaScale*normcdf(betaSens.*contrast + gammaXoff,0,1);

end