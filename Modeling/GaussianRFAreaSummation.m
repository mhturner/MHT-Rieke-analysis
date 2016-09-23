function res = GaussianRFAreaSummation(params,spotSizes)
% res = GaussianRFAreaSummation(params, spotSizes)
% Kc = params(1); sigmaC = params(2);
% MHT 05/2016
Kc = params(1); sigmaC = params(2);
c = 2*sigmaC^2;
r = spotSizes ./ 2;
res = Kc.*(1 - exp(-(r.^2)./c));