function res = gaussFilter1D(sigma)
% res = gaussFilter1D(sigma)
x = -5*sigma:5*sigma;
amp = exp((-x.^2)./(2*sigma^2));
amp = amp./(sum(amp)); %integrates to 1

res.x = x;
res.amp = amp;
end