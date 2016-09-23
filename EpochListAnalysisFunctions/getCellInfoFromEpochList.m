function cellInfo = getCellInfoFromEpochList(epochList)
% res = getCellInfoFromEpochList(epochList)
% MHT 5/17/16
ip = inputParser;
ip.addRequired('epochList',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericEpochList'));
ip.parse(epochList);
epochList = ip.Results.epochList;

firstCellID = char(epochList.elements(1).cell.label);
for epochIndex = 1:epochList.length
    thisCellID =  char(epochList.elements(epochIndex).cell.label);
    if ~strcmp(firstCellID,thisCellID)
        error('Mulitple cells included in this epochList')
    end
end

cellID = char(epochList.firstValue.cell.label);
if epochList.firstValue.protocolSettings.keySet.contains('source:type')
    cellType = epochList.firstValue.protocolSettings('source:type');
    si = strfind(cellType,'\');
    if isempty(si)

    else %sub-class (e.g. "RGC\ ON-parasol")
        cellType = cellType(si+1:end);
        si = strfind(cellType,'-');
        cellType(si) = [];
    end
    
    if or(strcmp(cellType,'unknown'), isempty(cellType))
        keywords = char(epochList.keywords);
        cellType = checkAgainstKeywords(keywords);
    end
    
else
    cellKeywords = char(epochList.keywords);
    cellType = checkAgainstKeywords(cellKeywords); 
end

cellInfo.cellID = cellID;
cellInfo.cellType = cellType;

function res = checkAgainstKeywords(keywords)
    if ~isempty(strfind(keywords,'ONparasol'))
        res = char('ONparasol');
    elseif ~isempty(strfind(keywords,'OFFparasol'))
        res = char('OFFparasol');
    elseif ~isempty(strfind(keywords,'ONmidget'))
        res = char('ONmidget');
    elseif ~isempty(strfind(keywords,'OFFmidget'))
        res = char('OFFmidget');
    elseif ~isempty(strfind(keywords,'horizontal'))
        res = char('horizontal');
    else
        res = 'noCellTypeTag';
    end
end
    
end