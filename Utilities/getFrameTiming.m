function [frameTimes, frameRate] = getFrameTiming(frameMonitor,lcrFlag)
    %frameTimes in data points
    %frameRate, mean over all flips, is frames/dataPoint
    %MHT 3/31/16 ported over to symphony 2.0 and split lcr from oled
    
    if (lcrFlag == 0) %smooth out non-monotonicity (shows up on RigG)
       frameMonitor = lowPassFilter(frameMonitor, 360, 1/1e4); 
    end
    
    %shift & scale s.t. fr monitor lives on [0,1]
    frameMonitor = frameMonitor - min(frameMonitor);
    frameMonitor = frameMonitor./max(frameMonitor);
    
    ups = getThresCross(frameMonitor,0.5,1);
    downs = getThresCross(frameMonitor,0.5,-1);
    frameRate = 2/mean(diff(ups)); % 2 because ups are every two frames...
    
    if (lcrFlag == 1) %very fast, so frame times are clear directly from trace
       ups = [1 ups]; %first upswing missed
       timesOdd = ups;
       timesEven = downs;
       frameTimes = round(sort([timesOdd'; timesEven']));
       
    else %OLED monitor, slower
        %just get peaks/troughs between first and last flips
        tempFM = frameMonitor(ups(1):downs(end)); 
        [~,flipsEven] = getPeaks(tempFM,1);
        [~,flipsOdd] = getPeaks(tempFM,-1);
        flipsEven = flipsEven + ups(1);
        flipsOdd = [1 flipsOdd + ups(1)];
        frameTimes = round(sort([flipsOdd'; flipsEven']));
    end

end