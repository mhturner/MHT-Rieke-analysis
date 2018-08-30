%%

TreeToHdf5(tree,'LinearEquivalentDiscModSurround - Fig.2')



%%
h5disp('DOVEScsAdditivity.h5')

%%

loc = '/@(list)splitOnCellType(list)=RGC_ON-parasol/cell.label=20170713Gc6/protocolSettings(stimulusIndex)=9/@(list)splitOnRecKeyword(list)=exc/Surround';


frmon = h5read('DOVEScsAdditivity.h5',[loc,'/','FrameMonitor']);
resp = h5read('DOVEScsAdditivity.h5',[loc,'/','response']);

figure(20); clf; subplot(211)
plot(resp')
subplot(212)
plot(frmon')
%%

keyList = split(string(aa.keySet),',');
for kk = 1:5%length(keyList)
    newKey = replace(keyList(kk),'[','');
    newKey = replace(newKey,']','');
    newKey = strtrim(newKey);
    
    newVal = aa.get(newKey);
    disp(newKey)
    disp(newVal)
    disp('------')
    
end

