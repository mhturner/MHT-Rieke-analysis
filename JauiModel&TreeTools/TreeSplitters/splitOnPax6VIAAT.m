function V = splitOnPax6VIAAT(epoch)
keywords = char(epoch.keywords);
if ~isempty(strfind(keywords,'VIAATKO'))
    V = char('VIAATKO');
elseif ~isempty(strfind(keywords,'wt'))
    V = char('wt');
else
    V = 'no KoWt tag';
end
