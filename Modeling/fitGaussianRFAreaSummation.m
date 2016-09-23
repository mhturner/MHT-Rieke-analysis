function [Kc, sigmaC] = fitGaussianRFAreaSummation(spotSizes,responses,params0)
    % [Kc, sigmaC] = fitGaussianRFAreaSummation(spotSizes,responses,params0)
    % MHT 05/2016
    LB = [0, 0]; UB = [Inf Inf];
    fitOptions = optimset('MaxIter',2000,'MaxFunEvals',600*length(LB),'Display','off');
    
    [params, ~, ~]=lsqcurvefit(@GaussianRFAreaSummation,params0,spotSizes,responses,LB,UB,fitOptions);
    Kc = params(1); sigmaC = params(2);
end
