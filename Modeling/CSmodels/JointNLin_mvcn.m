function res=JointNLin_mvcn(x,y,alpha,mu,sigma,epsilon)
    res=alpha .* mvncdf([x;y]',mu,sigma) + epsilon;
end