function res = fitCRF_cumGauss(contrast,response,params0)


    LB = [0, -Inf, -Inf, -Inf]; UB = [Inf Inf Inf Inf];
    fitOptions = optimset('MaxIter',1500,'MaxFunEvals',1000*length(LB),'Display','off');
    [params, resnorm, residual]=lsqnonlin(@CRF_err,params0,LB,UB,fitOptions,contrast,response);
    alphaScale = params(1);
    betaSens = params(2);
    gammaXoff = params(3);
    epsilonYoff = params(4);
    
    predResp = CRFcumGauss(contrast,alphaScale,betaSens,gammaXoff,epsilonYoff);
    ssErr=sum((response-predResp).^2); %sum of squares of residual
    ssTot=sum((response-mean(response)).^2); %total sum of squares
    rSquared=1-ssErr/ssTot; %coefficient of determination

    res.alphaScale=params(1);
    res.betaSens=params(2);
    res.gammaXoff=params(3);
    res.epsilonYoff = params(4);
    res.rSquared=rSquared;
end

function err = CRF_err(params,contrast,response)
    %error fxn for fitting CRF fxn with contrast spots...
    alphaScale = params(1);
    betaSens = params(2);
    gammaXoff = params(3);
    epsilonYoff = params(4);

    fit = CRFcumGauss(contrast,alphaScale,betaSens,gammaXoff,epsilonYoff);
    err = (fit - response);
end