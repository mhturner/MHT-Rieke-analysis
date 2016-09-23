function V = splitOnF1F2CenterSize(epoch)
%For merging F1 & F2 as a function of contrast data from ContrastF1F2 and
%SplitFieldCentering
    if epoch.protocolSettings.keySet.contains('spotDiameter') %SplitFieldCentering
        V = epoch.protocolSettings('spotDiameter');
    elseif epoch.protocolSettings.keySet.contains('apertureDiameter') %ContrastF1F2
        V = epoch.protocolSettings('apertureDiameter');
    end
end
