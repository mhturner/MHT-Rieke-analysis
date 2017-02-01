function V = splitOnShortProtocolID(epoch)
temp = char(epoch.protocolID);
dotInds = strfind(temp,'.');
V = temp(dotInds(end) + 1 : end);

