function res=CSModel_SharedNL(C,S,a,alpha,beta,gamma,epsilon)
%based on EJ's 2001 paper, parameterized
%cumulative normal distribution with ~intuitivie parameters:
%alpha is maximum conductance
%beta is sensitivity of NL to genSignal
%gamma determines where the threshold/shoulder is
%epsilon shifts the whole thing up or down
%takes as input weighted sum (i.e. (aX + y)), where a is scale factor for x

    res=alpha*normcdf(beta.*(a.*C + S) + gamma,0,1)+epsilon;
    
end