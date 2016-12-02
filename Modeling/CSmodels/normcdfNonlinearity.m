function res=normcdfNonlinearity(x,alpha,beta,gamma,epsilon)
%based on EJ's 2001 paper, parameterized
%cumulative normal distribution with ~intuitivie parameters:
%alpha is maximum conductance
%beta is sensitivity of NL to genSignal
%gamma determines where the threshold/shoulder is
%epsilon shifts the whole thing up or down

    res = alpha * normcdf(beta .* x + gamma,0,1)+epsilon;

end