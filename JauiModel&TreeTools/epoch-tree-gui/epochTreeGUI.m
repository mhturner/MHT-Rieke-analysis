classdef epochTreeGUI < handle
    
    properties
        epochTree;
        showEpochs = true;
        figure;
        isBusy = false;
        
    end
    
    properties(Hidden = true)
        title = 'Epoch Tree GUI';
        busyTitle = 'Epoch Tree GUI (busy...)';
        
        fontSize = 14;
        xDivLeft = .4;
        xDivRight = .1;
        yDiv = .05;
        
        treeBrowser = struct();
        plottingCanvas = struct();
    end
    
    methods
        function self = epochTreeGUI(epochTree, varargin)
            if nargin < 1
                return
            end
            
            self.epochTree = epochTree;

            if nargin > 1
                if any(strcmp(varargin, 'noEpochs'))
                    self.showEpochs = false;
                end
            end
            
            self.buildUIComponents;
            self.isBusy = true;
            self.initTreeBrowser;
            self.plotEpochData();
            self.isBusy = false;
            
        end
        
        function delete(self)
            % attempt to close figure
            if ~isempty(self.figure) ...
                    && ishandle(self.figure) ...
                    && strcmp(get(self.figure, 'BeingDeleted'), 'off')
                close(self.figure);
            end
        end
        
        %%% top-level
        
        function buildUIComponents(self)
            % clean out the figure
            if ~isempty(self.figure) && ishandle(self.figure)
                delete(self.treeBrowser.panel);
                delete(self.plottingCanvas.panel);
                clf(self.figure);
            else
                self.figure = figure; %#ok<CPROP>
            end
            
            set(self.figure, ...
                'Name',         self.title, ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none', ...
                'Units',      'normalized', ...
                'OuterPosition', [.1 1 .6 .6], ...
                'DeleteFcn',    {@epochTreeGUI.figureDeleteCallback, self}, ...
                'HandleVisibility', 'on');

            % new panels and widgets
            self.buildTreeBrowserUI();
            self.buildPlottingCanvasUI();
        end
        
        function rebuildUIComponents(self)
            % save existing graphical tree object
            graphTree = self.treeBrowser.graphTree;
            
            self.buildUIComponents;
            self.isBusy = true;
            
            % rewire existing graphicalTree to new axes
            self.treeBrowser.graphTree = graphTree;
            self.treeBrowser.graphTree.axes = self.treeBrowser.treeAxes;
            self.refreshBrowserNodes;
            
            self.isBusy = false;
        end
        
        function set.isBusy(self, isBusy)
            self.isBusy = isBusy;
            if isBusy
                set(self.figure, 'Name', self.busyTitle);
            else
                set(self.figure, 'Name', self.title);
            end
            drawnow;
        end
        
        function set.xDivLeft(self, xDivLeft)
            self.xDivLeft = xDivLeft;
            self.rebuildUIComponents;
        end
        
        function set.xDivRight(self, xDivRight)
            self.xDivRight = xDivRight;
            self.rebuildUIComponents;
        end
        
        function set.yDiv(self, yDiv)
            self.yDiv = yDiv;
            self.rebuildUIComponents;
        end
        
        function set.fontSize(self, fontSize)
            self.fontSize = fontSize;
            self.rebuildUIComponents;
        end
        
        %%% tree browser
        
        function buildTreeBrowserUI(self)
            % main tree browser panel and axes
            self.treeBrowser.panel = uipanel( ...
                ...'Title',    'tree browser', ...
                'Parent',   self.figure, ...
                'HandleVisibility', 'off', ...
                'Units',    'normalized', ...
                'Position', [0 0 self.xDivLeft 1]);
            self.treeBrowser.treeAxes = axes( ...
                'Parent',	self.treeBrowser.panel, ...
                'HandleVisibility', 'on', ...
                'Units',    'normalized', ...
                'Position', [0 .05 1 .9]);
            
            [~, shortKeys] = getEpochTreeSplitString(self.epochTree);
            self.treeBrowser.splitKeys = uicontrol( ...
                'Parent',   self.treeBrowser.panel, ...
                'Style',    'popupmenu', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   shortKeys, ...
                'HorizontalAlignment', 'left', ...
                'Position', [0 .95 1 .05], ...
                'TooltipString', 'EpochTree split keys');
            self.treeBrowser.setExample = uicontrol( ...
                'Parent',   self.treeBrowser.panel, ...
                'Callback', @(obj, event)self.setExample, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'set example', ...
                'HorizontalAlignment', 'left', ...
                'Position', [0 0 .3 .05], ...
                'TooltipString', 'toggle selected node as example');
            self.treeBrowser.clearExample = uicontrol( ...
                'Parent',   self.treeBrowser.panel, ...
                'Callback', @(obj, event)self.clearExample, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'clear examples', ...
                'HorizontalAlignment', 'left', ...
                'Position', [.35 0 .3 .05], ...
                'TooltipString', 'clear all example nodes');
            self.treeBrowser.pan = uicontrol( ...
                'Parent',   self.treeBrowser.panel, ...
                'Callback', @(obj, event)self.panTreeBrowserCallback(obj), ...
                'Style',    'togglebutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'pan', ...
                'HorizontalAlignment', 'left', ...
                'Position', [.7 0 .15 .05], ...
                'TooltipString', 'activate axes grab-and-drag mode');
            self.treeBrowser.refresh = uicontrol( ...
                'Parent',   self.treeBrowser.panel, ...
                'Callback', @(obj, event)self.refreshTreeBrowserCallback, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'refresh', ...
                'HorizontalAlignment', 'left', ...
                'Position', [.85 0 .15 .05], ...
                'TooltipString', 're-read EpochTree data');
        end
        
        function initTreeBrowser(self)
            if isfield(self.treeBrowser, 'graphTree') && isobject(self.treeBrowser.graphTree)
                delete(self.treeBrowser.graphTree);
            end
            
            % new graphicalTree object
            graphTree = graphicalTree(self.treeBrowser.treeAxes, 'EpochTree');
            graphTree.nodesSelectedFcn = {@epochTreeGUI.refreshUIForNodeSelection, self};
            graphTree.nodeBecameCheckedFcn = {@epochTreeGUI.nodeDataTakesFlag};
            graphTree.draw;
            self.treeBrowser.graphTree = graphTree;
            
            % populate grahical tree with EpochTree and Epoch objects
            if ~isempty(self.epochTree) %GWS, only check I need here?
                self.marryEpochNodesToWidgets(self.epochTree, graphTree.trunk);
            end
            
            self.epochTree.custom.put('display', java.util.HashMap());
            self.epochTree.custom.get('display').put('name', 'EpochTree');
            self.epochTree.custom.get('display').put('color', [0 0 0]);
            self.epochTree.custom.get('display').put('backgroundColor', 'none');
            self.refreshBrowserNodes(true);
        end
        
        function marryEpochNodesToWidgets(self, epochNode, browserNode)
            browserNode.userData = epochNode;
            
            % node appearance
            if isempty(epochNode.custom.get('isSelected'))
                epochNode.custom.put('isSelected',false);
            end
            
            if isobject(epochNode.splitValue)
                display.name = epochNode.splitValue.toString();
            else
                display.name = num2str(epochNode.splitValue);
            end
            display.color = [0 0 0];
            display.backgroundColor = 'none';
            epochNode.custom.put('display', riekesuite.util.toJavaMap(display));
            
            % other nodes may be Epoch capsules
            epochNode.custom.put('isCapsule', false);
            
            if epochNode.isLeaf && self.showEpochs
                % base case: special nodes with Epoch data
                epochs = epochNode.epochList.elements;
                for ii = 1:length(epochs)
                    ep = epochs(ii);
                    if isempty(ep.isSelected)
                        ep.isSelected = true;
                    end
                    
                    epochWidget = browserNode.tree.newNode(browserNode);
                    epochWidget.userData = ep;
                    
                    epochWidget.isChecked = ep.isSelected;
                    epochWidget.name = sprintf('%3d: %d-%02d-%02d %d:%d:%d', ii, ep.startDate);
                    epochWidget.textColor = [0 0 0];
                    epochWidget.textBackgroundColor = [1 .85 .85];
                end
                
            else
                % recur: new browserNode for each child node
                if ~isempty(epochNode.children) && epochNode.children.length > 0
                    children = epochNode.children.elements;
                    for ii = 1:length(children)
                        childWidget = browserNode.tree.newNode(browserNode);
                        self.marryEpochNodesToWidgets(children(ii), childWidget);
                    end
                end
            end
        end
        
        function refreshBrowserNodes(self, updateAllNodes)
            startNode = self.treeBrowser.graphTree.trunk;
            if nargin < 2
                updateAllNodes = true;
            end
            
            self.isBusy = true;
            self.readEpochTreeNodeDisplayState(startNode,updateAllNodes);
            self.treeBrowser.graphTree.trunk.countCheckedDescendants;
            self.treeBrowser.graphTree.draw;
            self.isBusy = false;
        end
        
        function readEpochTreeNodeDisplayState(self, browserNode, updateAllNodes)
            nodeData = browserNode.userData;
            if isa(nodeData,'edu.washington.rieke.jauimodel.AuiEpoch')
                updateThisNode = false;
            elseif (updateAllNodes)
                updateThisNode = true;
            else
                updateThisNode = nodeData.custom.get('isToUpdate');
            end
            
            if (updateThisNode)
                nodeData.custom.put('isToUpdate',false);
                if nodeData.custom.get('isCapsule');
                    % reconcile capsule node with encapsulated Epoch
                    epoch = nodeData.epochList.firstValue;
                    nodeData.custom.put('isSelected',epoch.isSelected);
                    browserNode.isChecked = epoch.isSelected;
                else
                    browserNode.isChecked =  nodeData.custom.get('isSelected');
                end

                % name
                    browserNode.name = nodeData.custom.get('display').get('name');


                % text color
                    browserNode.textColor = nodeData.custom.get('display').get('color');


                % background color
                    browserNode.textBackgroundColor = nodeData.custom.get('display').get('backgroundColor');

            end
            
            % recur: set child selections
            for ii = 1:browserNode.numChildren
                self.readEpochTreeNodeDisplayState(browserNode.getChild(ii),updateAllNodes);
            end
        end
        
        function setExample(self,nodes)
            self.isBusy = true;
            if nargin < 2
                % toggle example tag on selected node(s)
                nodes = self.getSelectedEpochTreeNodes;
            end
            
            for nn = 1:length(nodes)
                if nodes{nn}.custom.get('isExample') %turn off example
                    nodes{nn}.custom.put('isExample',false);
                    nodes{nn}.custom.get('display').put('backgroundColor','none');
                else %turn on example
                    nodes{nn}.custom.put('isExample',true);
                    nodes{nn}.custom.get('display').put('backgroundColor','r');
                end
                nodes{nn}.custom.put('isToUpdate',true);
            end
            self.refreshBrowserNodes(false);
            self.isBusy = false;
        end
        
        function clearExample(self)
            self.isBusy = true;
            for nn = 1:self.epochTree.descendentsDepthFirst.length
                self.epochTree.descendentsDepthFirst(nn).custom.put('isExample',false); %undo previous example settings
                self.epochTree.descendentsDepthFirst(nn).custom.get('display').put('backgroundColor','none');
                self.epochTree.descendentsDepthFirst(nn).custom.put('isToUpdate',true);
            end
            self.refreshBrowserNodes(false);
            self.isBusy = false;
        end
        
        function panTreeBrowserCallback(self, widget)
            p = pan(self.figure);
            if get(widget, 'Value')
                % STUPID, axes will not pan when HandleVisibility=off
                %   even for the pan button in builtin figure toolbar
                set(self.treeBrowser.treeAxes, 'HandleVisibility', 'on');
                set(p, 'Enable', 'on');
                setAllowAxesPan(p, self.treeBrowser.treeAxes, true);
            else
                set(self.treeBrowser.treeAxes, 'HandleVisibility', 'off');
                set(p, 'Enable', 'off');
                setAllowAxesPan(p, self.treeBrowser.treeAxes, false);
            end
        end
        
        function refreshTreeBrowserCallback(self)
            allEpochs = getTreeEpochs(self.epochTree);
            allEpochs.refresh;
            if isfield(self.treeBrowser, 'graphTree')
                self.refreshBrowserNodes;
            end
        end
        
        function showSplitKeyStringForSelectedNode(self)
            if (self.treeBrowser.graphTree.selectionSize == 1)
                [nodes, ~] = self.treeBrowser.graphTree.getSelectedNodes;
                % split strings stored in a popup menu
                %   jump to key for selected tree depth
                numKeys = length(get(self.treeBrowser.splitKeys, 'String'));
                keyIndex = max(min(numKeys, nodes{1}.depth), 1);
                set(self.treeBrowser.splitKeys, 'Value', keyIndex);
            end
        end
        
        function epochTreeNodes = getSelectedEpochTreeNodes(self) %capsule stuff
            [nodes, ~] = self.treeBrowser.graphTree.getSelectedNodes;
            epochTreeNodes = cell(size(nodes));
            
            for ii = 1:length(epochTreeNodes)
                nodeData = nodes{ii}.userData;
                
                if isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpochTree')
                    % easy, return the EpochTree
                    epochTreeNodes{ii} = nodeData;
                    
                elseif isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpoch')
                    % encapsulate the Epoch, cache the capsule
                    disp('selecting a capsule')
                    capsuleNode = self.encapsulateEpochForBrowserNode(nodes{ii});
                    nodes{ii}.userData = capsuleNode;
                    epochTreeNodes{ii} = capsuleNode;
                end
            end
        end
        
        function capsuleNode = encapsulateEpochForBrowserNode(self, browserNode)
            % browserNode.userData is an auimodel.Epoch
            %   encapsulate the Epoch in an EpochTree, replace userData
            %need to fix this
            epoch = browserNode.userData;
            listFactory = edu.washington.rieke.Analysis.getEpochListFactory();
            treeFactory = edu.washington.rieke.Analysis.getEpochTreeFactory();
            
            epochList = listFactory.create();
            epochList.append(epoch);
            %epochList.populateStreamNames;
            
            capsuleNode = treeFactory.create(epochList, {'protocolSettings.acquirinoEpochNumber'}); %temp hack
            capsuleNode.custom.put('isCapsule', true);
            capsuleNode.custom.put('isSelected', epoch.isSelected);
            
            % node appearance should be customizable
            display.name = browserNode.name;
            display.color = browserNode.textColor;
            display.backgroundColor = browserNode.textBackgroundColor;
            capsuleNode.custom.put('display', riekesuite.util.toJavaMap(display));
            
            % wire capsule node to tree, but not reciprocally
            browserParent = self.treeBrowser.graphTree.nodeList.getValue(browserNode.parentKey);
            %capsuleNode.parent = browserParent.userData; %can't do this now!
        end
        
        function cellArray = javaArray2CellArray(~, javaArray)
            cellArray = cell(length(javaArray), 1);
            for i = 1 : length(javaArray)
                cellArray{i} = javaArray(i);
            end
        end

        %%% plotting canvas
        function buildPlottingCanvasUI(self)
            % big panel for plotting or custom tools
            self.plottingCanvas.panel = uipanel( ...
                ...'Title',    'plotting canvas', ...
                'Parent',   self.figure, ...
                'HandleVisibility', 'on', ...
                'Units',    'normalized', ...
                'Position', [self.xDivLeft self.yDiv 1-self.xDivLeft 1-self.yDiv]);
        end
        
        function plotEpochData(self)
            self.isBusy = true;
            nodes = self.getSelectedEpochTreeNodes;
            singleEpoch(nodes{1}, self.plottingCanvas.panel, 0)
            self.isBusy = false;
        end
        
        function nodes = getSelectedTreeLevel(self)
            curNode = self.getSelectedEpochTreeNodes{1};
            levelsDown = 0;
            while ~isempty(curNode.parent)
                curNode = curNode.parent;
                levelsDown = levelsDown+1;
            end
            nodes = getTreeLevel(self.epochTree,levelsDown);
        end

    end
    
    methods(Static) %capsule stuff
        % This method gets hammered during recursive flagging
        % static method is *way* faster than instance method
        function nodeDataTakesFlag(browserNode)
            nodeData = browserNode.userData;
            if isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpoch') %epoch capsule node
                epoch = nodeData;
                epoch.setIsSelected(browserNode.isChecked);
            else %node
                nodeData.custom.put('isSelected',browserNode.isChecked);
            end
        end
        
        function refreshUIForNodeSelection(~, self)
            self.showSplitKeyStringForSelectedNode;
            self.plotEpochData; %refresh view in plot panel
        end

        
        % when the GUI figure closes, try to delete the gui object
        function figureDeleteCallback(~, ~, gui)
            gui.isBusy = true;
            if isobject(gui)
                if isfield(gui.treeBrowser, 'graphTree')
                    % destroy handle references to reduce closing time
                    gui.treeBrowser.graphTree.forgetExternalReferences;
                    gui.treeBrowser.graphTree.forgetInternalReferences;
                end
                if isvalid(gui)
                    delete(gui);
                end
            end
        end
    end
end
