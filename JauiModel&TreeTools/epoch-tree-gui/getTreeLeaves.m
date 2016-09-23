function l = getTreeLeaves(epochTree, onlySelected)
%Get cell array of leaf nodes (optionally, only selected)
%
%   l is a cell array containing any leaf nodes of epochTree.  If
%   onlySelected is true, l contains only those leaf nodes where
%   EpochTree.custom.isSelected is true.
%
%   epochTree is an auimodel.EpochTree with all your data.
%
%   getTreeLeaves is a utility used by epochTreeGUI and some
%   analysis-filter-view functions.
%
%%%SU
%   tree = getFixtureTree;
%   elements = tree.leafNodes.toCell;
%   for ii = 1:length(elements)
%       leaf = elements{ii};
%       leaf.custom.isSelected = false;
%   end
%
%   allLeaves = length(getTreeLeaves(tree));
%   noLeaves = length(getTreeLeaves(tree, true));
%   leaf = tree.leafNodes.firstValue;
%   leaf.custom.isSelected = true;
%   oneLeaf = length(getTreeLeaves(tree, true));
%   clear tree;
%%%TS noLeaves == 0
%%%TS allLeaves > 0
%%%TS oneLeaf == 1

% benjamin.heasly@gmail.com
%   17 Feb. 2009

if nargin < 2 || isempty(onlySelected)
    onlySelected = false;
end

l = {};
if isjava(epochTree) && strcmp(class(epochTree), 'edu.washington.rieke.jauimodel.AuiEpochTree')
    if epochTree.isLeaf
        leaf = epochTree;
        if ~onlySelected || (leaf.custom.containsKey('isSelected') && leaf.custom('isSelected'))
            % use a leaf node as-is
            l{1} = epochTree;
        end
    else
        % build a grand list of leaves
        elements = epochTree.leafNodes.elements;
        for ii = 1:length(elements)
            leaf = elements(ii);
            if ~onlySelected || (leaf.custom.containsKey('isSelected') && leaf.custom('isSelected'))
                l{end+1,1} = leaf;
            end
        end
    end
end
