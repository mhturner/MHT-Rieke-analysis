function [fit] = hill(beta, x)

fit = 1.0 ./ (1 + (beta(1) ./ x).^beta(2));
