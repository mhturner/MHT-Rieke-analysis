function elNew = sortEpochList_time(epochList)
listFactory = edu.washington.rieke.Analysis.getEpochListFactory();
elNew = listFactory.create;
%Sorts epochList by startDate
%for Symphony data
%MHT 9/4/14

if ~strcmp(epochList.class,'edu.washington.rieke.symphony.generic.GenericEpochList')
   error('epochList should be a riekesuite epoch list') 
end

nEpochs = epochList.length;
timeStamp = zeros(1,nEpochs);
for j=1:nEpochs
    curEpoch = epochList.elements(j);
    timeStamp(j) = 24*60*60*curEpoch.startDate(3) + 60*60*curEpoch.startDate(4) + 60*curEpoch.startDate(5) + curEpoch.startDate(6);
end
[sortedEpochs, Ind] = sort(timeStamp);

for j=1:nEpochs
    elNew.append(epochList.valueByIndex(Ind(j)));
end


end