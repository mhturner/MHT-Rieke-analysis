function EpochList_Filtered = filterEpochListByEpochGroups(EpochList,targetGroups,IncludeExclude)
ip = inputParser;
expectedIncludeExclude = {'Include','Exclude'};
ip.addRequired('EpochList',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericEpochList'));

ip.addRequired('targetGroups',@iscell);
ip.addRequired('IncludeExclude',@(x)any(validatestring(x,expectedIncludeExclude)));

ip.parse(EpochList,targetGroups,IncludeExclude);
EpochList = ip.Results.EpochList;
targetGroups = ip.Results.targetGroups;
IncludeExclude = ip.Results.IncludeExclude;

listFactory = edu.washington.rieke.Analysis.getEpochListFactory();
EpochList_Filtered = listFactory.create;
for ee = 1:EpochList.length
   CurrentLabel = EpochList.elements(ee).protocolSettings('epochGroup:label');
   if strcmp(IncludeExclude,'Include')
       go = ismember(CurrentLabel,targetGroups);
   elseif strcmp(IncludeExclude,'Exclude')
       go = ~ismember(CurrentLabel,targetGroups);
   end
   if (go)
       EpochList_Filtered.append(EpochList.elements(ee));
   end
    
end
end