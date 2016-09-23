classdef graphicalTree < handle
    
    properties
        name;
        axes;
        figure;
        isBusy = false;
        
        selectionSize;
        
        % feval({fcn{1}, nodes, fcn{2:end}})
        nodesExpandedFcn;
        nodesCheckedFcn;
        nodesSelectedFcn;
        nodeBecameCheckedFcn;
    end
    
    properties(Hidden = true)
        axParent;
        
        trunk;
        nodeList;
        userDataList;
        widgetList;
        
        drawCount = 0;
        initialWidgets = 100;
        selectedWidgetKeys;
    end
    
    methods
        function self = graphicalTree(ax, name)
            
            self.nodeList = graphicalTreeList;
            self.userDataList = graphicalTreeList;
            self.widgetList = graphicalTreeList;
            
            if nargin > 1
                self.name = name;
            end
            self.trunk = self.newNode([], self.name);
            self.trunk.isExpanded = true;
            
            if nargin > 0
                % set.axes method does significant axes config.
                self.axes = ax;
                
                % assume a bunch of widgets are needed up front
                for ii = 1:self.initialWidgets
                    widget = graphicalTreeNodeWidget(self);
                end
                
                % start with trunk selected
                self.clearWidgetSelections;
                self.addWidgetToSelection(1);
                self.draw;
            end
        end
        
        function node = newNode(self, parent, name, isVisibleDescendant)
            if nargin < 2
                parent = [];
            end
            if nargin < 3
                name = '';
            end
            if nargin < 4
                isVisibleDescendant = true;
            end
            
            node = graphicalTreeNode(name, isVisibleDescendant);
            self.nodeList.append(node);
            
            node.selfKey = self.nodeList.length;
            node.tree = self;
            if isobject(parent) && isa(parent, 'graphicalTreeNode')
                node.parentKey = parent.selfKey;
                node.depth = parent.depth+1;
                parent.addChild(node);
            end
        end
        
        function index = appendNodeUserData(self, userData)
            self.userDataList.append(userData);
            index = self.userDataList.length;
        end
        
        function nodeUserData = getNodeUserData(self, index)
            nodeUserData = self.userDataList.getValue(index);
        end
        
        function setNodeUserData(self, index, nodeUserData)
            self.userDataList.setValue(index, nodeUserData);
        end
        
        function includeInDraw(self, node)
            % make sure there's a graphical widget available for caller
            self.drawCount = self.drawCount + 1;
            if self.drawCount > self.widgetList.length
                % double up on widgets
                for ii = self.drawCount:(self.widgetList.length*2)
                    widget = graphicalTreeNodeWidget(self);
                end
            end
            widget = self.widgetList.getValue(self.drawCount);
            widget.boundNodeKey = node.selfKey;
        end
        
        function draw(self);
            % figure out which nodes to draw
            self.drawCount = 0;
            self.trunk.includeUnburied;
            
            % set widget appearances
            widgets = self.widgetList.getAllValues;
            for ii = 1:self.drawCount
                widgets{ii}.bindNode(ii);
            end
            
            % hide unused widgets
            for ii = self.drawCount+1:self.widgetList.length;
                widgets{ii}.unbindNode;
            end
        end
        
        function redrawChecks(self)
            % quickly(?) redraw only visible widgets
            widgets = self.widgetList.getAllValues;
            for ii = 1:self.drawCount
                widget = widgets{ii};
                node = self.nodeList.getValue(widget.boundNodeKey);
                widget.checkBox.isChecked = node.isChecked;
                widget.checkBox.isAlternateChecked = widget.partialSelection;
            end
        end
        
        function addWidgetToSelection(self, widgetKey)
            if ~any(self.selectedWidgetKeys == widgetKey)
                self.selectedWidgetKeys(end+1) = widgetKey;
                widget = self.widgetList.getValue(widgetKey);
                widget.showHighlight(true);
            end
        end
        
        function removeWidgetFromSelection(self, widgetKey)
            loc = self.selectedWidgetKeys == widgetKey;
            if any(loc)
                widget = self.widgetList.getValue(widgetKey);
                widget.showHighlight(false);
                self.selectedWidgetKeys = self.selectedWidgetKeys(~loc);
            end
        end
        
        function toggleWidgetSelection(self, widgetKey)
            if any(self.selectedWidgetKeys == widgetKey)
                self.removeWidgetFromSelection(widgetKey);
            else
                self.addWidgetToSelection(widgetKey);
            end
        end
        
        function clearWidgetSelections(self)
            for key = self.selectedWidgetKeys
                widget = self.widgetList.getValue(key);
                widget.showHighlight(false);
            end
            self.selectedWidgetKeys = [];
        end
        
        function growSelectionToIncludeWidget(self, widgetKey)
            low = min(self.selectedWidgetKeys);
            high = max(self.selectedWidgetKeys);
            range = [];
            if widgetKey < low
                range = widgetKey:high;
            elseif widgetKey > high
                range = low:widgetKey;
            end
            for key = range
                self.addWidgetToSelection(key)
            end
        end
        
        function widgetKey = getWidgetOutsideSelection(self, direction, onlyFlagged)
            % widgetKeys as interchangable with draw count, row
            if direction < 0
                widgetKey = max(min(self.selectedWidgetKeys)-1, 1);
            elseif direction > 0
                widgetKey = min(max(self.selectedWidgetKeys)+1, self.drawCount);
            end
            
            % skip to a checked node
            if onlyFlagged
                widget = self.widgetList.getValue(widgetKey);
                while isobject(widget) && ~widget.checkBox.isChecked
                    widgetKey = widgetKey + direction;
                    widget = self.widgetList.getValue(widgetKey);
                end
                widgetKey = min(max(1,widgetKey), self.drawCount);
            end
        end
        
        function expandCollapseFromWidgets(self, widgetKeys, isExpanded)
            self.isBusy = true;
            drawnow;
            
            [selectedNodes, selectedNodeKeys] = self.getSelectedNodes;
            for ii = 1:length(widgetKeys)
                widget = self.widgetList.getValue(widgetKeys(ii));
                node = self.nodeList.getValue(widget.boundNodeKey);
                node.isExpanded = isExpanded;
            end
            self.draw;
            
            % recover widget selections for previously selected nodes
            self.clearWidgetSelections;
            for ii = 1:self.drawCount
                widget = self.widgetList.getValue(ii);
                if any(widget.boundNodeKey == selectedNodeKeys)
                    self.addWidgetToSelection(ii);
                end
            end
            
            drawnow;
            self.fireNodesExpandedFcn(widgetKeys);
            
            self.isBusy = false;
            drawnow;
        end
        
        function toggleCheckBoxOnWidgets(self, widgetKeys)
            self.isBusy = true;
            drawnow;
            
            % toggle with recursive set for selected widgets
            %   go bottom to top to prevent sub-tree hell
            descending = sort(widgetKeys, 2, 'descend');
            for key = descending
                widget = self.widgetList.getValue(key);
                node = self.nodeList.getValue(widget.boundNodeKey);
                node.setChecked(~node.isChecked);
            end
            self.redrawChecks;
            
            drawnow;
            self.fireNodesCheckedFcn(widgetKeys);
            
            self.isBusy = false;
            drawnow;
        end
        
        function [nodes, nodeKeys] = getSelectedNodes(self)
            n = length(self.selectedWidgetKeys);
            nodes = cell(1, n);
            nodeKeys = zeros(1, n);
            for ii = 1:n
                widget = self.widgetList.getValue(self.selectedWidgetKeys(ii));
                nodes{ii} = self.nodeList.getValue(widget.boundNodeKey);
                nodeKeys(ii) = widget.boundNodeKey;
            end
        end
        
        function [data, dataKeys] = getSelectedNodeData(self)
            [nodes, nodeKeys] = self.getSelectedNodes;
            n = length(nodes);
            data = cell(1, n);
            dataKeys = zeros(1, n);
            for ii = 1:n
                node = nodes{ii};
                data{ii} = self.userDataList.getValue(node.userDataKey);
                dataKeys(ii) = node.userDataKey;
            end
        end
        
        function forgetExternalReferences(self)
            self.nodesExpandedFcn = [];
            self.nodesCheckedFcn = [];
            self.nodesSelectedFcn = [];
            self.nodeBecameCheckedFcn = [];
            self.userDataList.removeAllValues;
        end
        
        function forgetInternalReferences(self)
            widgets = self.widgetList.getAllValues;
            for ii = 1:self.widgetList.length
                delete(widgets{ii});
            end
            self.widgetList.removeAllValues;
            
            nodes = self.nodeList.getAllValues;
            for ii = 1:self.nodeList.length
                delete(nodes{ii});
            end
            self.nodeList.removeAllValues;
            
            delete(self.trunk);
            self.trunk = [];
        end
        
        function set.axes(self, ax)
            self.axes = ax;
            
            % make consistent
            self.axParent = get(self.axes, 'Parent');
            [xl, yl] = graphicalTree.getAxesLimsFromAxesSize(self.axes);
            set(self.axes, ...
                'Box',      'off', ...
                'Color',    [1 1 1], ...
                'Units',    'normalized', ...
                'XLim',     xl, ...
                'XScale',   'linear', ...
                'XTick',    [], ...
                'YLim',     yl, ...
                'YScale',   'linear', ...
                'YTick',    [], ...
                'YDir',     'reverse', ...
                'HitTest',  'on', ...
                'SortMethod', 'depth', ...
                'Visible',  'on');
            
            % parent object might not be a figure
            %   get the containing figure
            obj = self.axes;
            while ~strcmp(get(obj, 'Type'), 'figure')
                obj = get(obj, 'Parent');
            end
            self.figure = obj;
            
            set(self.figure, ...
                'Renderer', 'painters', ...
                'Units',    'pixels', ...
                'WindowScrollWheelFcn', {@graphicalTree.scrollAxesWithMouseWheel, self}, ...
                'KeyPressFcn',  {@graphicalTree.respondToKeypress, self});
            
            set(self.axParent, ...
                'ResizeFcn', {@graphicalTree.adjustAxesOnContainerResize, self.axes});
            
            % inform graphical children
            if self.widgetList.length > 0
                widgets = self.widgetList.getAllValues;
                for ii = 1:self.widgetList.length
                    widgets{ii}.axes = ax;
                end
                self.draw;
            end
        end
        
        function set.isBusy(self, isBusy)
            self.isBusy = isBusy;
            for key = self.selectedWidgetKeys
                widget = self.widgetList.getValue(key);
                widget.showBusy(isBusy);
            end
        end
        
        function n = get.selectionSize(self)
            n = length(self.selectedWidgetKeys);
        end
        
        function fireNodesExpandedFcn(self, nodes)
            fcn = self.nodesExpandedFcn;
            if length(fcn) == 1
                feval(fcn{1}, nodes);
            elseif length(fcn) > 1
                feval(fcn{1}, nodes, fcn{2:end});
            end
        end
        
        function fireNodesCheckedFcn(self, nodes)
            fcn = self.nodesCheckedFcn;
            if length(fcn) == 1
                feval(fcn{1}, nodes);
            elseif length(fcn) > 1
                feval(fcn{1}, nodes, fcn{2:end});
            end
        end
        
        function fireNodesSelectedFcn(self, nodes)
            fcn = self.nodesSelectedFcn;
            if length(fcn) == 1
                feval(fcn{1}, nodes);
            elseif length(fcn) > 1
                feval(fcn{1}, nodes, fcn{2:end});
            end
        end
        
        function fireNodeBecameCheckedFcn(self, node)
            fcn = self.nodeBecameCheckedFcn;
            if length(fcn) == 1
                feval(fcn{1}, node);
            elseif length(fcn) > 1
                feval(fcn{1}, node, fcn{2:end});
            end
        end
    end
    
    methods(Static)
        
        % UI callbacks
        function respondToKeypress(fig, event, self)
            switch event.Key
                case {'uparrow', 'downarrow'}
                    % unmodified: replace selection with widget
                    % shift: grow selection
                    % control: replace with next flagged node
                    % shift-control: grow to next flagged widget
                    
                    onlyFlagged = any(strcmp(event.Modifier, 'control'));
                    if strcmp(event.Key, 'uparrow')
                        direction = -1;
                    else
                        direction = +1;
                    end
                    
                    nextWidget = self.getWidgetOutsideSelection(direction, onlyFlagged);
                    if any(strcmp(event.Modifier, 'shift'))
                        self.growSelectionToIncludeWidget(nextWidget);
                    else
                        self.clearWidgetSelections;
                        self.addWidgetToSelection(nextWidget);
                    end
                    
                    drawnow;
                    self.fireNodesSelectedFcn(self.selectedWidgetKeys);
                    
                case {'leftarrow', 'rightarrow'}
                    % expand or contract nodes from selected widgets
                    isExpanded = strcmp(event.Key, 'rightarrow');
                    self.expandCollapseFromWidgets(self.selectedWidgetKeys, isExpanded);
                    
                case {'f'}
                    % toggle all checks
                    self.toggleCheckBoxOnWidgets(self.selectedWidgetKeys);
            end
        end
        
        function respondToWidgetExpanderClick(expandBox, event, widgetKey, self)
            self.expandCollapseFromWidgets(widgetKey, expandBox.isChecked)
        end
        
        function respondToWidgetCheckboxClick(checkBox, event, widgetKey, self)
            self.toggleCheckBoxOnWidgets(widgetKey);
        end
        
        function respondToWidgetLabelClick(label, event, widgetKey, self)
            % Matlab can't supply a Mac-style command-click
            %   or multiple click modifiers
            type = get(self.figure, 'SelectionType');
            switch type
                case 'normal'
                    % unmodified: clear selection and select clicked node
                    self.clearWidgetSelections;
                    self.addWidgetToSelection(widgetKey);
                    
                case 'extend'
                    % shift: grow selection to clicked node
                    self.growSelectionToIncludeWidget(widgetKey);
                    
                case 'alt'
                    % control: toggle selection at clicked node
                    self.toggleWidgetSelection(widgetKey);
            end
            
            drawnow;
            self.fireNodesSelectedFcn(self.selectedWidgetKeys);
        end
        
        function scrollAxesWithMouseWheel(fig, event, self)
            % scroll when mouse is over the axes container
            mousePoint = get(fig, 'CurrentPoint');
            containerPos = getpixelposition(self.axParent);
            if mousePoint(1) >= containerPos(1) ...
                    && mousePoint(1) <= containerPos(1) + containerPos(3) ...
                    && mousePoint(2) >= containerPos(2) ...
                    && mousePoint(2) <= containerPos(2) + containerPos(4) ...
                    
                % keep axes on the tree
                widget = self.widgetList.getValue(self.drawCount);
                treeBottom = widget.position;
                yl = get(self.axes, 'YLim');
                inc = event.VerticalScrollCount;
                axTop = min(max(yl(1)+inc, 0), treeBottom(2));
                set(self.axes, 'YLim', [axTop, axTop+yl(2)-yl(1)]);
            end
        end
        
        % graphical containers callbacks
        function [xl, yl] = getAxesLimsFromAxesSize(ax)
            oldUnits = get(ax, 'Units');
            set(ax, 'Units', 'characters');
            pos = get(ax, 'Position');
            xl = [0, max(eps, pos(3))];
            yl = [0, max(eps, pos(4))];
            set(ax, 'Units', oldUnits);
        end
        
        function adjustAxesOnContainerResize(container, event, ax)
            [xl, yl] = graphicalTree.getAxesLimsFromAxesSize(ax);
            set(ax, 'XLim', xl, 'YLim', yl);
        end
    end
end