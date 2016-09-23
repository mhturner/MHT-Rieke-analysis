function res=CSModel_IndependentNL(C,S,alphaC,betaC,gammaC,alphaS,betaS,gammaS,epsilon)
%based on EJ's 2001 paper, parameterized
%cumulative normal distribution with ~intuitivie parameters:
%alpha is maximum conductance
%beta is sensitivity of NL to genSignal
%gamma determines where the threshold/shoulder is
%epsilon shifts the whole thing up or down
%takes as input generator signals / "pre-nLin input" for center & surround


    Rc = alphaC*normcdf(betaC.*C + gammaC,0,1)+epsilon;
    Rs = alphaS*normcdf(betaS.*S + gammaS,0,1);

    res=Rc + Rs;
    
end

