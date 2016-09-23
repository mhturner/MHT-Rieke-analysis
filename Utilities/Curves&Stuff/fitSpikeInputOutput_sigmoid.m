function res = fitSpikeInputOutput_sigmoid(inputs,response,params0)


    LB = [-Inf, -Inf, 0, -Inf]; UB = [Inf Inf Inf,0];
    fitOptions = optimset('MaxIter',1500,'MaxFunEvals',600*length(LB));
    [params, resnorm, residual]=lsqnonlin(@errfun,params0,LB,UB,fitOptions,inputs,response);
    k = params(1);
    c0 = params(2);
    amp = params(3);
    yOFF = params(4);

    predResp = SpikeOutput_sigmoid(inputs,k,c0,amp,yOFF);
    ssErr=sum((response-predResp).^2); %sum of squares of residual
    ssTot=sum((response-mean(response)).^2); %total sum of squares
    rSquared=1-ssErr/ssTot; %coefficient of determination

    res.k=params(1);
    res.c0=params(2);
    res.amp=params(3);
    res.yOFF = params(4);
    res.rSquared=rSquared;
end

function err = errfun(params,inputs,response)
    %error fxn for fitting CRF fxn with contrast spots...
    k = params(1);
    c0 = params(2);
    amp = params(3);
    yOFF = params(4);

    fit = SpikeOutput_sigmoid(inputs,k,c0,amp,yOFF);
    err = (fit - response);
end