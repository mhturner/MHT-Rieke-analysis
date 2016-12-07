function V = splitOnCenterOffset(epoch)
%For merging symphony data that has old protocol-specific centerOffset and
%newer, background stage centerOffset. For brief overlap period, they are
%additive.
    

    if epoch.protocolSettings.keySet.contains('centerOffset') %
        protocolOffset = epoch.protocolSettings('centerOffset');
        protocolOffset = convertJavaArrayList(protocolOffset); %convert to matlab array
    else
        protocolOffset = 0;
    end
    if epoch.protocolSettings.keySet.contains('background:Microdisplay Stage@localhost:centerOffset') %
        stageOffset = epoch.protocolSettings('background:Microdisplay Stage@localhost:centerOffset');
        stageOffset = convertJavaArrayList(stageOffset); %convert to matlab array
    else
        stageOffset = 0;
    end
    totalOffset = protocolOffset + stageOffset;
    V = num2str(totalOffset);
end