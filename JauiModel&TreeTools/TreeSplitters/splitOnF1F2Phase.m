function V = splitOnF1F2Phase(epoch)
%For merging F1 & F2 as a function of contrast data from ContrastF1F2 and
%SplitFieldCentering
    if epoch.protocolSettings.keySet.contains('splitField') %SplitFieldCentering
        if epoch.protocolSettings('splitField')
            V = 'F2';
        else
            V = 'F1';
        end
    elseif epoch.protocolSettings.keySet.contains('currentPhase') %ContrastF1F2
        if epoch.protocolSettings('currentPhase') == 0
            V = 'F1';
        elseif epoch.protocolSettings('currentPhase') == 90
            V = 'F2';
        end
    end
end
