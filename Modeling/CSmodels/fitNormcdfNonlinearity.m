function res = fitNormcdfNonlinearity(x,response,params0)
%res is params for fxn normcdfNonlinearity

%params is [alpha, beta, gamma, epsilon]
% % params0=[max(resp), mean(diff(resp)), 0, 0]';

LB = [0 0 -Inf -Inf]; UB = [Inf Inf Inf max(response(:))];
fitOptions = optimset('MaxIter',1500,'MaxFunEvals',600*length(LB),'Display','off');
[params, ~, residual]=lsqnonlin(@modelErrorFxn,params0,LB,UB,fitOptions,x,response);
ssErr=sum(residual.^2); %sum of squares of residual
ssTot=sum((response(:)-mean(response(:))).^2); %total sum of squares
rSquared=1-ssErr/ssTot; %coefficient of determination

res.alpha=params(1);
res.beta=params(2);
res.gamma=params(3);
res.epsilon=params(4);
res.rSquared=rSquared;
end
function err = modelErrorFxn(params,x,response)
%error fxn for fitting summed NLinearity function
alpha = params(1);
beta = params(2);
gamma = params(3);
epsilon = params(4);

fit = normcdfNonlinearity(x,alpha,beta,gamma,epsilon);
err = fit - response;
end