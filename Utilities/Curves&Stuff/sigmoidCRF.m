function res = sigmoidCRF(contrast,k,c0,amp,yOff)

res = yOff + amp ./ (1 + exp(-k.*(contrast - c0)));
end