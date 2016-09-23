function V = splitOnPatchSampling_NatImage(epoch)
%early vs. later versions of symphony 2.0 protocols LinearEquivalentDisc or
%LinearEquivalentAnnulus
    if epoch.protocolSettings.keySet.contains('patchSampling') %later versions
        V = epoch.protocolSettings('patchSampling');
    else %first version. Random patches
        V = 'random';
    end
end
