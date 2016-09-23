classdef graphicalTreeNode < handle
    
    properties
        tree;
        selfKey;
        parentKey;
        childrenKeys;
        userDataKey;
        
        depth = 0;
        numDescendants = 0;
        numCheckedDescendants = 0;
        
        name = 'no name';
        textColor = [0 0 0];
        textBackgroundColor = 'none'
        userData = [];
        
        isExpanded = false;
        isChecked = false;
        
        % when becomeChecked, should children becomeChecked, too?
        recursiveCheck = true;
        
        % when accounting for checked descendants, does this node count?
        isVisibleDescandant = true;
    end
    
    methods
        function self = graphicalTreeNode(name, isVisibleDescandant)
            if nargin > 0
                self.name = name;
            end
            if nargin > 1
                self.isVisibleDescandant = isVisibleDescandant;
            end
        end
        
        function parent = getParent(self)
            if ~isempty(self.parentKey)
                parent = self.tree.nodeList.getValue(self.parentKey);
            else
                parent = [];
            end
        end
        
        function addChild(self, child)
            self.childrenKeys(end+1) = child.selfKey;
            if child.isVisibleDescandant
                self.incrementDescendants;
            end
        end
        
        function child = getChild(self, ii)
            if  ii > length(self.childrenKeys)
                child = [];
            else
                child = self.tree.nodeList.getValue(self.childrenKeys(ii));
            end
        end
        
        function n = numChildren(self)
            n = length(self.childrenKeys);
        end
        
        function incrementDescendants(self)
            self.numDescendants = self.numDescendants + 1;
            parent = self.getParent;
            if isobject(parent)
                parent.incrementDescendants;
            end
        end
        
        function incrementCheckedDescendants(self, diff)
            self.numCheckedDescendants = self.numCheckedDescendants + diff;
            parent = self.getParent;
            if isobject(parent)
                parent.incrementCheckedDescendants(diff);
            end
        end
        
        function setChecked(self, isChecked)
            % recursive down tree
            checkDiff = isChecked - self.isChecked;
            ncdWas = self.numCheckedDescendants;
            ncd = self.becomeChecked(isChecked);
            
            diff = self.isVisibleDescandant*checkDiff + ncd - ncdWas;
            parent = self.getParent;
            if isobject(parent) && diff ~= 0
                % recursive up tree
                parent.incrementCheckedDescendants(diff);
            end
        end
        
        function ncd = becomeChecked(self, isChecked)
            checkChanged = xor(self.isChecked, isChecked);
            self.isChecked = isChecked;
            
            % call out to user
            if checkChanged && isobject(self.tree)
                self.tree.fireNodeBecameCheckedFcn(self);
            end
            
            % count up checked descendants
            ncd = 0;
            if self.numChildren
                if self.recursiveCheck
                    % count and set
                    ncd = 0;
                    for ii = 1:self.numChildren
                        child = self.getChild(ii);
                        ncd = ncd + (isChecked && child.isVisibleDescandant) + child.becomeChecked(isChecked);
                    end
                    self.numCheckedDescendants = ncd;
                else
                    % only count
                    ncd = countCheckedDescendants(self);
                end
            end
        end
        
        function ncd = countCheckedDescendants(self)
            if self.numChildren
                ncd = 0;
                for ii = 1:self.numChildren
                    child = self.getChild(ii);
                    ncd = ncd + (child.isChecked && child.isVisibleDescandant) + child.countCheckedDescendants;
                end
            else
                ncd = 0;
            end
            self.numCheckedDescendants = ncd;
        end
        
        function includeUnburied(self)
            
            % tree should configure a graphical widget for this node
            self.tree.includeInDraw(self);
            
            % recur on children
            if self.isExpanded && self.numChildren
                for ii = 1:self.numChildren
                    child = self.getChild(ii);
                    child.includeUnburied;
                end
            end
        end
        
        function userData = get.userData(self)
            if isobject(self.tree) && ~isempty(self.userDataKey)
                userData = self.tree.userDataList.getValue(self.userDataKey);
            else
                userData = [];
            end
        end
        
        function set.userData(self, userData)
            if isobject(self.tree)
                if isempty(self.userDataKey)
                    self.tree.userDataList.append(userData);
                    self.userDataKey = self.tree.userDataList.length;
                else
                    self.tree.userDataList.setValue(self.userDataKey, userData);
                end
            end
        end
    end
end