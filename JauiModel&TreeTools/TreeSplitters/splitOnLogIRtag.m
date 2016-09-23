function V = splitOnLogIRtag(epoch)
keywords = char(epoch.keywords);
if ~isempty(strfind(keywords,'12.0'))
    V = strvcat('12.0');
elseif ~isempty(strfind(keywords,'13.6'))
    V = strvcat('13.6');
else
    V = 'noRecordingTag';
end
