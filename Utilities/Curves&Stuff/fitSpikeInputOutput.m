function res = fitSpikeInputOutput(inputs,response,params0)
    % res = fitSpikeInputOutput(inputs,response,params0)
    % Fitting wrapper for SpikeOutput_cumGauss

    LB = [0, -Inf, -Inf]; UB = [Inf Inf Inf];
    fitOptions = optimset('MaxIter',1500,'MaxFunEvals',600*length(LB));
    [params, ~, ~]=lsqnonlin(@errFun,params0,LB,UB,fitOptions,inputs,response);
    alphaScale = params(1);
    betaSens = params(2);
    gammaXoff = params(3);
    
    predResp = SpikeOutput_cumGauss(inputs,alphaScale,betaSens,gammaXoff);
    ssErr=sum((response-predResp).^2); %sum of squares of residual
    ssTot=sum((response-mean(response)).^2); %total sum of squares
    rSquared=1-ssErr/ssTot; %coefficient of determination

    res.alphaScale=params(1);
    res.betaSens=params(2);
    res.gammaXoff=params(3);
    res.rSquared=rSquared;
end

function err = errFun(params,inputs,response)
    %error fxn
    alphaScale = params(1);
    betaSens = params(2);
    gammaXoff = params(3);

    fit = SpikeOutput_cumGauss(inputs,alphaScale,betaSens,gammaXoff);
    err = (fit - response);
end