%Parameters for simulated RF:
centerSigma = 40;
Kc = 1;
Ks = 0.5;
surroundSigma = 100;

%stimululs
FilterSize = 600;
spotSize = 0:10:600; %diameter of spot

% center and surround filters
for x = 1:FilterSize
    for y = 1:FilterSize
        RFCenter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (centerSigma^2)));
        RFSurround(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (surroundSigma^2)));
    end
end
%normalize
RFCenter = RFCenter ./ sum(RFCenter(:));
RFSurround = RFSurround ./ sum(RFSurround(:));
%combine for DoG model
RF = Kc * RFCenter - Ks * RFSurround;

[rr, cc] = meshgrid(1:FilterSize,1:FilterSize);
for ss = 1:length(spotSize) %get responses to each spot
    currentRadius = spotSize(ss)/2;
    spotBinary = sqrt((rr-(FilterSize/2)).^2+(cc-(FilterSize/2)).^2)<=currentRadius;
    response(ss) = sum(sum(RF.*spotBinary));
end

%fit DoG to simulated RF responses:
%initialize parameters. Choose reasonable starting points that are
%generally going to be true - i.e. sigmaC < sigmaS and kC > kS
params0 = [1 30 0.1 200]; 
[Kc,sigmaC,Ks,sigmaS] = fitDoGAreaSummation(spotSize,response,params0);
fitX = 0:600;
fitY = DoGAreaSummation([Kc,sigmaC,Ks,sigmaS],fitX);

figure(1); clf; plot(spotSize,response,'bo')
hold on;
plot(fitX,fitY,'k-')