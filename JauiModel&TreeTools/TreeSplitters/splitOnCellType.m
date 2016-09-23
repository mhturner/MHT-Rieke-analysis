function V = splitOnCellType(epoch)
    if epoch.protocolSettings.keySet.contains('source:type')
        V = epoch.protocolSettings('source:type');
        if or(strcmp(V,'unknown'), isempty(V))
            keywords = char(epoch.keywords);
            V = checkAgainstKeywords(keywords);
        end
    else %symphony 1: cell type is added as a keyword
        keywords = char(epoch.keywords);
        V = checkAgainstKeywords(keywords);
    end

    function res = checkAgainstKeywords(keywords)
        if ~isempty(strfind(keywords,'ONparasol'))
            res = char('RGC\ON-parasol');
        elseif ~isempty(strfind(keywords,'OFFparasol'))
            res = char('RGC\OFF-parasol');
        elseif ~isempty(strfind(keywords,'ONmidget'))
            res = char('RGC\ON-midget');
        elseif ~isempty(strfind(keywords,'OFFmidget'))
            res = char('RGC\OFF-midget');
        elseif ~isempty(strfind(keywords,'horizontal'))
            res = char('horizontal');
        else
            res = 'noCellTypeTag';
        end
    end
end
