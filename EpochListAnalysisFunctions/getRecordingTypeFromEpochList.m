function recType = getRecordingTypeFromEpochList(epochList)
% recType = getRecordingTypeFromEpochList(epochList)
% Uses keyword tagging and standard rec type keywords:
% standardRecTypes = {'exc','inh','extracellular','gClamp','iClamp'};
%   or 'noRecordingTag'
% MHT 5/17/16
    ip = inputParser;
    ip.addRequired('epochList',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericEpochList'));
    ip.parse(epochList);
    epochList = ip.Results.epochList;

    standardRecTypes = {'exc','inh','extracellular','gClamp','iClamp'};
    keywords = char(epochList.keywords);

    recType = [];
    for rr = 1:length(standardRecTypes)
        if ~isempty(strfind(keywords,standardRecTypes{rr})) 
            recType = standardRecTypes{rr};
        end
    end
    if isempty(recType)
        recType = 'noRecordingTag';
    end

end