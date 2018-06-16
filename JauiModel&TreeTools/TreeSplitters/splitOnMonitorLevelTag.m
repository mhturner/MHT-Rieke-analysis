function V = splitOnMonitorLevelTag(epoch)
keywords = char(epoch.keywords);
if ~isempty(strfind(keywords,'monMed'))
    V = char('monMed');
elseif ~isempty(strfind(keywords,'monHigh'))
    V = char('monHigh');
else
    V = 'no monitor tag';
end
