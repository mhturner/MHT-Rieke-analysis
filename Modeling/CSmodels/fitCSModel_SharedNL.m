function res = fitCSModel_SharedNL(x,y,z_data,params0)
%fits summed nonlinearity, r = f(aX + Y)
%res is params for fxn summedNLin

%params is [a, alpha, beta, gamma, epsilon]
% % params0=[2, max(z_data), mean(diff(z_data))/mean(diff(x+y)), 0, 0]';

LB = [0 0 0 -Inf -Inf]; UB = [Inf Inf Inf Inf max(z_data(:))];
fitOptions = optimset('MaxIter',1500,'MaxFunEvals',600*length(LB),'Display','off');
[params, ~, residual]=lsqnonlin(@modelErrorFxn,params0,LB,UB,fitOptions,x,y,z_data);
ssErr=sum(residual.^2); %sum of squares of residual
ssTot=sum((z_data(:)-mean(z_data(:))).^2); %total sum of squares
rSquared=1-ssErr/ssTot; %coefficient of determination

res.a=params(1);
res.alpha=params(2);
res.beta=params(3);
res.gamma=params(4);
res.epsilon=params(5);
res.rSquared=rSquared;
end
function err = modelErrorFxn(params,x,y,response)
%error fxn for fitting summed NLinearity function
a = params(1);
alpha = params(2);
beta = params(3);
gamma = params(4);
epsilon = params(5);

%reshape x,y and response to arrays
[X1,X2] = meshgrid(x',y');
response=reshape(response,[1, size(response,1)*size(response,2)]);


fit = CSModel_SharedNL(X1(:)',X2(:)',a,alpha,beta,gamma,epsilon);
err = fit - response;
end