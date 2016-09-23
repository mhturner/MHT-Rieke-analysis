function V = splitOnOLEDLevel(epoch)

if epoch.protocolSettings.containsKey('background:Microdisplay Stage@localhost:microdisplayBrightness') == 1
    V = epoch.protocolSettings('background:Microdisplay Stage@localhost:microdisplayBrightness');
elseif epoch.protocolSettings.containsKey('oledBrightness') == 1 %symphony version 1
    brightnessValue = epoch.protocolSettings('oledBrightness');
    if brightnessValue == 23
        V = char('maximum');
    elseif brightnessValue == 25
        V = char('high');
    elseif brightnessValue == 73
        V = char('medium');
    elseif brightnessValue == 120
        V = char('low');
    elseif brightnessValue == 229
        V = char('minimum');
    end
else
    V = 'Not OLED';
end

% function res = checkAgainstKeywords(keywords)
%     if ~isempty(strfind(keywords,'min'))
%         res = char('minimum');
%     elseif ~isempty(strfind(keywords,'low'))
%         res = char('low');
%     elseif ~isempty(strfind(keywords,'med'))
%         res = char('medium');
%     elseif ~isempty(strfind(keywords,'high'))
%         res = char('high');
%     elseif ~isempty(strfind(keywords,'maximum'))
%         res = char('maximum');
%     else
%         res = 'noCellTypeTag';
%     end
% end

end
