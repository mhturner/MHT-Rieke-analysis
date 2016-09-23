function V = splitOnHoldingSignal(epoch)
    if epoch.protocolSettings.keySet.contains('stimuli:Amp1:offset') %symphony 2
        V = epoch.protocolSettings('stimuli:Amp1:offset');
    elseif epoch.protocolSettings.keySet.contains('background:Amplifier_Ch1')  %symphony 1
        V = epoch.protocolSettings('background:Amplifier_Ch1');
    end
end
