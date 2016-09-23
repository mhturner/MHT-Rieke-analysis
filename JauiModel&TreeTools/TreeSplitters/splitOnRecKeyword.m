function V = splitOnRecKeyword(epoch)
keywords = char(epoch.keywords);
if ~isempty(strfind(keywords,'exc'))
    V = char('exc');
elseif ~isempty(strfind(keywords,'inh'))
    V = char('inh');
elseif ~isempty(strfind(keywords,'extracellular'))
    V = char('extracellular');
elseif ~isempty(strfind(keywords,'gClamp'))
    V = char('gClamp');
elseif ~isempty(strfind(keywords,'iClamp'))
    V = char('iClamp');
else
    V = 'noRecordingTag';
end
