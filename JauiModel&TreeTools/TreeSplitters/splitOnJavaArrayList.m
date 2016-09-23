function V = splitOnJavaArrayList(epoch,splitProtocolSetting)

V = num2str(convertJavaArrayList(epoch.protocolSettings(splitProtocolSetting)));
end
