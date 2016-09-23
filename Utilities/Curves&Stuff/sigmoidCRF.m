function res = sigmoidCRF(contrast,k,c0,amp,yOff)
    % res = sigmoidCRF(contrast,k,c0,amp,yOff)
    % Modified sigmoid function, to fit a smooth curve to
    % contrast-response data
    %   k determines the sensitivity / slope
    %   amp is an absolute scaling factor in y
    %   c0 is an offset along the x axis (contrast)
    %   yOff is an offset along the y axis (response)
    
    res = yOff + amp ./ (1 + exp(-k.*(contrast - c0)));
    
end