function V = splitOnPatchContrast_NatImage(epoch)
%early vs. later versions of symphony 2.0 protocols LinearEquivalentDisc or
%LinearEquivalentAnnulus
    if epoch.protocolSettings.keySet.contains('patchContrast') %later versions
        V = epoch.protocolSettings('patchContrast');
    else %first version. Random patches
        V = 'all';
    end
end
