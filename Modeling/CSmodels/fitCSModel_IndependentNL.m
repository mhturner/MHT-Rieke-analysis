function res = fitCSModel_IndependentNL(C,S,response,params0)
%Takes in binned generator signals for Center and Surround, along with
%corresponding response - same input as fitting joint model
%fits independent center-surround model: R = nC(hC*C) + nS(hS*S)
%where nC and nS are modified cumulative gaussian NLinearities
%res is params for fxn indCSmodel

%params is [alphaC, betaC, gammaC,...
%           alphaS, betaS, gammaS, epsilon]
% params0=[max(z_data), mean(diff(z_data))/mean(diff(C)), 0, max(z_data),
% mean(diff(z_data))/mean(diff(S)), 0, 0]';


LB = [0 0 -Inf 0 0 -Inf -Inf];
UB = [Inf Inf Inf Inf Inf Inf Inf];
fitOptions = optimset('MaxIter',1500,'MaxFunEvals',600*length(LB),'Display','off');
[params, ~, residual]=lsqnonlin(@modelErrorFxn,params0,LB,UB,fitOptions,C,S,response);
ssErr=sum(residual.^2); %sum of squares of residual
ssTot=sum((response(:)-mean(response(:))).^2); %total sum of squares
rSquared=1-ssErr/ssTot; %coefficient of determination

res.alphaC=params(1);
res.betaC=params(2);
res.gammaC=params(3);
res.alphaS=params(4);
res.betaS=params(5);
res.gammaS=params(6);
res.epsilon=params(7);

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
epsilon = params(7);

%reshape x,y and response to arrays
[X1,X2] = meshgrid(x',y');
response=reshape(response,[1, size(response,1)*size(response,2)]);

fit = CSModel_IndependentNL(X1(:)',X2(:)',alphaC,betaC,gammaC,alphaS,betaS,gammaS,epsilon);
err = fit - response;
end
