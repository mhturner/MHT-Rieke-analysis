function res = fitCSModel_ThreeNL(C,S,response,params0)
%Takes in binned generator signals for Center and Surround, along with
%corresponding response - same input as fitting joint model
%fits thee-NL center-surround model: R = nShared[nC(hC*C) + nS(hS*S)]
%where nC, nS, and nShared are modified cumulative gaussian NLinearities
%res is params for fxn CSModel_ThreeNL

%params is [alphaC, betaC, gammaC,...
%           alphaS, betaS, gammaS,...
%           alphaShared, betaShared, gammaShared,...
%           epsilon]
% params0=[max(z_data), mean(diff(z_data))/mean(diff(C)), 0, max(z_data),
% mean(diff(z_data))/mean(diff(S)), 0, 0]';


LB = [-1 -Inf -1 -1 -Inf -1 -Inf -Inf -Inf -Inf];
UB = [1 Inf 1 1 Inf 1 Inf Inf Inf Inf];
fitOptions = optimset('MaxIter',1500,'MaxFunEvals',600*length(LB),'Display','off');
[params, ~, residual]=lsqnonlin(@modelErrorFxn,params0,LB,UB,fitOptions,C,S,response);
ssErr=sum(residual.^2); %sum of squares of residual
ssTot=nansum((response(:)-nanmean(response(:))).^2); %total sum of squares
rSquared=1-ssErr/ssTot; %coefficient of determination

res.alphaC=params(1);
res.betaC=params(2);
res.gammaC=params(3);

res.alphaS=params(4);
res.betaS=params(5);
res.gammaS=params(6);

res.alphaShared=params(7);
res.betaShared=params(8);
res.gammaShared=params(9);

res.epsilon=params(10);

res.rSquared=rSquared;
end

function err = modelErrorFxn(params,x,y,response)
%error fxn for fitting summed NLinearity function
alphaC = params(1);
betaC = params(2);
gammaC = params(3);

alphaS = params(4);
betaS = params(5);
gammaS = params(6);

alphaShared = params(7);
betaShared = params(8);
gammaShared = params(9);

epsilon = params(10);

%reshape x,y and response to arrays
[X1,X2] = meshgrid(x',y');
response=reshape(response,[1, size(response,1)*size(response,2)]);
% take out any NaNs in z data, don't fit with those points
fitInds = find(~isnan(response));
response = response(fitInds);

fit = CSModel_ThreeNL(X1(fitInds),X2(fitInds),...
    alphaC,betaC,gammaC,alphaS,betaS,gammaS,alphaShared,betaShared,gammaShared,epsilon);
err = fit - response;
end
