function res = fitCRF_sigmoid(contrast,response,params0)
    % res = fitCRF_sigmoid(contrast,response,params0)
    % Fitting wrapper for sigmoidCRF

    LB = [0, -Inf 0 -Inf]; UB = [Inf Inf Inf Inf];
    fitOptions = optimset('MaxIter',1500,'MaxFunEvals',600*length(LB),'Display','off');
    [params, ~, ~]=lsqnonlin(@CRF_err,params0,LB,UB,fitOptions,contrast,response);
    k = params(1);
    c0 = params(2);
    amp = params(3);
    yOff = params(4);
    
    predResp = sigmoidCRF(contrast,k,c0,amp,yOff);

    ssErr=sum((response-predResp).^2); %sum of squares of residual
    ssTot=sum((response-mean(response)).^2); %total sum of squares
    rSquared=1-ssErr/ssTot; %coefficient of determination

    res.k=params(1);
    res.c0=params(2);
    res.amp=params(3);
    res.yOff=params(4);
    res.rSquared=rSquared;
end

function err = CRF_err(params,contrast,response)
    %error fxn for fitting CRF fxn with contrast spots...
    k = params(1);
    c0 = params(2);
    amp = params(3);
    yOff = params(4);
    
    fit = sigmoidCRF(contrast,k,c0,amp,yOff);
    err = (fit - response);
end