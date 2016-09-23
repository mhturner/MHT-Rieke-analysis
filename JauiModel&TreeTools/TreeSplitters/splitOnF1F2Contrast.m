function V = splitOnF1F2Contrast(epoch)
%For merging F1 & F2 as a function of contrast data from ContrastF1F2 and
%SplitFieldCentering

    if epoch.protocolSettings.keySet.contains('currentContrast') %ContrastF1F2
        V = epoch.protocolSettings('currentContrast');
    else %SplitFieldCentering
        V = epoch.protocolSettings('contrast');
    end
end
