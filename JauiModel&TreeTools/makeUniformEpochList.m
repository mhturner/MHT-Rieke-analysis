function [outEpochList outParams] = makeUniformEpochList(epochList_in,constantSettings,constrainedSettings)
    %takes in an epochList of a single protocol and a cell array of
    %protocol settings, specified as strings, and outputs a new epochList (which
    %is a subset of the input list) that includes only epochs with the same
    %values for parameters included in constantSettings. For settings with
    %more than one value present in epochList_in, majority rules. Also
    %spits out the value for each of the constantSettings
    %For specific parameter values, use constrained parameters in
    % MHT 9/24/14 - made
    % MHT 11/03/14 - added constrainedParameters option. Include only
    % epochs with indicated value for indicated parameters
    if ~strcmp(epochList_in.class,'edu.washington.rieke.symphony.generic.GenericEpochList')
       error('epochList_in should be a riekesuite epoch list') 
    end
    if nargin<3
        constrainedSettings = [];
    end

    settings = struct; %Tally up indicated parameter values
    for s = 1:length(constantSettings)
        settings.(constantSettings{s}) = [];
        for e = 1:epochList_in.length
            newValue = epochList_in.elements(e).protocolSettings.get(constantSettings{s});
            if strcmp(class(newValue),'java.util.ArrayList')
                newValue = convertJavaArrayList(newValue);
            end
            settings.(constantSettings{s}) = cat(1,settings.(constantSettings{s}),newValue);
        end
        [uniqueRow ia uniqueInd] = unique(settings.(constantSettings{s}),'rows');
        [count,ix]=max(accumarray(uniqueInd,1));
        majRow = uniqueRow(ix,:); %majority parameter value
        majSetting.(constantSettings{s}).value = majRow;
    end
    if (~isempty(constrainedSettings)) %tack on constrained settings...
        constFields = fieldnames(constrainedSettings);
        for t = 1:length(constFields)
            majSetting.(constFields{t}).value = constrainedSettings.(constFields{t});
        end
    end
    
    checkFields = fieldnames(majSetting);
    listFactory = edu.washington.rieke.Analysis.getEpochListFactory();
    elNew = listFactory.create;
    clear settings;
    for e = 1:epochList_in.length %for each epoch
        for f = 1:length(checkFields) %for each constrained parameter...
            ConstParams.(checkFields{f}) = majSetting.(checkFields{f}).value; %what should it be
            newValue = epochList_in.elements(e).protocolSettings.get(checkFields{f}); %what is it
            if strcmp(class(newValue),'java.util.ArrayList')
                newValue = convertJavaArrayList(newValue);
            end
            settings.(checkFields{f}) = newValue; 
        end
        skipEpoch = checkConstrainedParameters(ConstParams,settings);
        if (skipEpoch==0)
            elNew.append(epochList_in.elements(e));
        end
    end

    outEpochList = elNew;
    for f = 1:length(checkFields)
        outParams.(checkFields{f}) = settings.(checkFields{f});
    end

    disp(['Excluded ',num2str(epochList_in.length - elNew.length), ' epochs from epochList'])
        
end