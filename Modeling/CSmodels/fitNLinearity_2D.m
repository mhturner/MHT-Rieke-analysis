function res = fitNLinearity_2D(x,y,z_data,beta0)
%fits 2D nonlinearity with smooth surface which is a modified bivariate
%cumulative normal distribution
%   alpha*C(mu,sigma)+epsilon
%   where C is mvncdf() fxn
%x and y define axes 1 and 2 (bins centers, basically)
%z_data is an x by y matrix of response values

%beta is [alpha mu1 mu2 std1 std2 corr12 epsilon]

LB = [max(z_data(:)) min(x) min(y) 0 0 -1 -Inf]; UB = [Inf max(x) max(y) Inf Inf 1 0];
fitOptions = optimset('MaxIter',1500,'MaxFunEvals',600*length(LB),'Display','off');
[beta, ~, residual]=lsqnonlin(@BivarCumNorm_err,beta0,LB,UB,fitOptions,x,y,z_data);
ssErr=sum(residual.^2); %sum of squares of residual
ssTot=sum((z_data(:)-mean(z_data(:))).^2); %total sum of squares
rSquared=1-ssErr/ssTot; %coefficient of determination

res.alpha=beta(1);
res.mu=[beta(2) beta(3)];
res.sigma=[beta(4)^2 beta(6)*beta(4)*beta(5);beta(6)*beta(4)*beta(5) beta(5)^2];
res.epsilon=beta(7);
res.rSquared=rSquared;
end

function err = BivarCumNorm_err(beta,x,y,response)
%error fxn for fitting Bivariate Cumulative Normal surface to 2D
%nonlinearity
alpha=beta(1);
mu=[beta(2) beta(3)];
sigma1=beta(4); sigma2=beta(5); corr12=beta(6);
epsilon=beta(7);

sigma=[sigma1^2 corr12*sigma1*sigma2;corr12*sigma1*sigma2 sigma2^2];

%reshape x,y and response to arrays
[X1,X2] = meshgrid(x',y');
response=reshape(response,[size(response,1)*size(response,2),1]);

fit = JointNLin_mvcn(X1(:)',X2(:)',alpha,mu,sigma,epsilon);

err = fit - response;
end