function V = splitOnRadiusOrDiameter(epoch,paramString)
    %For protocols that transferred from Symphony 1 to 2 changing some
    %"radius" params to "diameter" paramString may be 'mask' or 'aperture'
    if epoch.protocolSettings.keySet.contains([paramString, 'Radius'])
        V = 2 * epoch.protocolSettings([paramString, 'Radius']);
    elseif epoch.protocolSettings.keySet.contains([paramString, 'Diameter'])
        V = epoch.protocolSettings([paramString, 'Diameter']);
    end
end
