function el = getTreeEpochs(epochTree, onlySelected)
%Get one EpochList with all Epochs in tree (optionally, only selected)
%
%   el is a single auimodel.EpochList containing all Epochs from epochTree.
%   If onlySelected is true, el contains only those Epochs where
%   Epoch.isSelected is true.
%
%   epochTree is an auimodel.EpochTree with all your data.
%
%   getTreeEpochs is a utility used by epochTreeGUI and some
%   analysis-filter-view functions.
%
%%%SU
%   tree = getFixtureTree;
%   el = getTreeEpochs(tree);
%   allEpochs = el.length;
%
%   elements = el.toCell;
%   for ii = 1:length(elements)
%       ep = elements{ii};
%       ep.isSelected = false;
%   end
%   sel = getTreeEpochs(tree, true);
%   noEpochs = sel.length;
%
%   ep = elements{1};
%   ep.isSelected = true;
%   sel = getTreeEpochs(tree, true);
%   oneEpoch = sel.length;
%
%   clear tree el sel ep
%%%TS allEpochs > 0
%%%TS noEpochs == 0
%%%TS oneEpoch == 1

% benjamin.heasly@gmail.com
%   2 Feb. 2009

if nargin < 2 || isempty(onlySelected)
    onlySelected = false;
end

listFactory = edu.washington.rieke.Analysis.getEpochListFactory();
el = listFactory.create();
if ~isempty(epochTree)
    
    if epochTree.isLeaf
        
        if onlySelected
            epochElements = epochTree.epochList.elements;
            for jj = 1:length(epochElements)
                epoch = epochElements(jj);
                if ~isempty(epoch.isSelected) && epoch.isSelected
                    el.append(epoch);
                end
            end
        else
            
            % use the leaf node's epochList verbatim
            el = epochTree.epochList;
        end
    else
        
        % build a grand EpochList
        leafElements = epochTree.leafNodes.elements;
        for ii = 1:length(leafElements)
            leaf = leafElements(ii);
            epochElements = leaf.epochList.elements;
            for jj = 1:length(epochElements)
                epoch = epochElements(jj);
                if ~onlySelected || (~isempty(epoch.isSelected) && epoch.isSelected)
                    el.append(epoch);
                end
            end
        end
    end
end

