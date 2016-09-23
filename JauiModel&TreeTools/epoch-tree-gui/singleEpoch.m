function singleEpoch(epochTree, fig, doInit)
%Show info about one Epoch at at time, under given EpochTree

% benjamin.heasly@gmail.com
%   2 Feb. 2009
import riekesuite.guitools.*;

if ~nargin && ~isobject(epochTree)
    disp(sprintf('%s needs an EpochTree', mfilename));
    return
end
if nargin < 2
    disp(sprintf('%s needs a figure', mfilename));
    return
end
if nargin < 3
    doInit = false;
end

% init when told, or when this is not the 'current function' of the figure
figData = get(fig, 'UserData');
if doInit || ~isfield(figData, 'currentFunction') || ~strcmp(figData.currentFunction, mfilename)
    % create new panel slider, info table
    delete(get(fig, 'Children'));
    figData.currentFunction = mfilename;
    x = .02;
    w = .96;
    noData = {...
        'number', []; ...
        'date', []; ...
        'isSelected', []; ...
        'includeInAnalysis', []; ...
        'tags', []};
    figData.infoTable = uitable('Parent', fig', ...
        'Units', 'normalized', ...
        'Position', [x .8, w, .18], ...
        'Data', noData, ...
        'RowName', {}, ...
        'ColumnName', [], ...
        'ColumnEditable', false);
    figData.panel = uipanel('Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [x .05 w .75]);
    figData.next = uicontrol('Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [x 0 w .05], ...
        'Style', 'slider', ...
        'Callback', {@plotNextEpoch, figData});
    set(fig, 'UserData', figData, 'ResizeFcn', {@canvasResizeFcn, figData});
    canvasResizeFcn(figData.panel, [], figData);
end

% get all Epochs under the given tree
el = getTreeEpochs(epochTree);
n = el.length;
if n
    set(figData.next, ...
        'Enable', 'on', ...
        'UserData', el, ...
        'Min',  1, ...
        'Max',  n+eps, ...
        'SliderStep', [1/n, 1/n], ...
        'Value', 1);
    plotNextEpoch(figData.next, [], figData);
else
    delete(get(figData.panel, 'Children'));
    set(figData.next, 'Enable', 'off');
end


function plotNextEpoch(slider, event, figData)
% slider control picks one Epoch
ind = round(get(slider, 'Value'));
el = get(slider, 'UserData');
ep = el.valueByIndex(ind);

% various Epoch info to table rows
infoData = get(figData.infoTable, 'Data');
infoData{1,2} = sprintf('%d of %d', ind, el.length);
infoData{2,2} = datestr(ep.startDate, 31);
infoData{3,2} = logical(ep.isSelected);
infoData{4,2} = logical(ep.includeInAnalysis);
tags = ep.keywords;
%if tags.isEmpty skip this for now
%    infoData{5,2} = 'no tags';
%else
%    infoData{5,2} = sprintf('%s, ',tags{:}); %how do I do this in jauimodel?
%end
set(figData.infoTable, 'Data', infoData);

set(figData.panel, 'Title', 'getting response data...');
drawnow;

% Epoch responses in subplots
temp = ep.responses.keySet;
temp.remove('Optometer');
resps = temp.toArray;
nResp = length(resps);
for ii = 1:nResp
    sp = subplot(nResp, 1, ii, 'Parent', figData.panel);
    cla(sp);

    respData = riekesuite.getResponseVector(ep, resps(ii));

    if ischar(respData)
        % dont' break when lazyLoads disabled
        ylabel(sp, respData);
    else
        line(1:length(respData), respData, 'Parent', sp);
        ylabel(sp, resps(ii));
    end
end

set(figData.panel, 'Title', 'responses:');
drawnow;

function canvasResizeFcn(panel, event, figData)
% set infoTable column widths proportionally
oldUnits = get(figData.infoTable, 'Units');
set(figData.infoTable, 'Units', 'pixels');
tablePos = get(figData.infoTable, 'Position');
set(figData.infoTable, 'Units', oldUnits);

set(figData.infoTable, 'ColumnWidth', {.2*tablePos(3), .65*tablePos(3)});
