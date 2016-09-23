function [splitString shortKeys] = getEpochTreeSplitString(epochTree)
%Make string to summarize EpochTree split parameters
%
%   Get splitValues from an EpochTree leaf node, pull off the last word of
%   each key, concatenate the words.
%
%   There is probably a better way to do this.  Could it be a method of
%   EpochTree or Map? The funny bit is shortening the key strings to get a
%   compact summary.

% benjamin.heasly@gmail.com
%   Jan. 2009

if ~nargin || isempty(epochTree)
    splitString = 'no EpochTree??';
    shortKeys = {''};
    return
end

if epochTree.isLeaf
    leaf = epochTree;
elseif epochTree.leafNodes.length > 0
    leaf = epochTree.leafNodes.firstValue;
else
    splitString = 'no leaf nodes??';
    shortKeys = {''};
    return
end

if leaf.custom.get('isCapsule') 
    splitString = 'Epoch capsule';
    shortKeys = {''};
    return
else
    map = leaf.splitValues;
end

keys = map.keySet.toArray;
shortKeys = cell(size(keys));
for ii = 1:length(keys)
    if isempty(keys(ii))
        % why does this ever happen?
        shortKeys{ii} = ' ';
    else
        %GWS 5/4/09
        key_str = keys(ii);
        token = regexp(key_str, '[:.]?([^:.]+)$', 'tokens');
        shortKeys(ii) = token{1};
    end
end
splitString = sprintf('-%s', shortKeys{:});