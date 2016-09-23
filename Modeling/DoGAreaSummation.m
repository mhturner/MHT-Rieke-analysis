function res = DoGAreaSummation(params, spotSizes)
% res = DoGAreaSummation(params, spotSizes)
% Kc = params(1); sigmaC = params(2); Ks = params(3); sigmaS = params(4);
% MHT 05/2016
Kc = params(1); sigmaC = params(2); Ks = params(3); sigmaS = params(4);
c_center = 2*sigmaC^2;
c_surround = 2*sigmaS^2;
r = spotSizes ./ 2;
res = Kc.*(1 - exp(-(r.^2)./c_center)) - Ks.*(1 - exp(-(r.^2)./c_surround));