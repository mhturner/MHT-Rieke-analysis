classdef graphicalTreeNodeWidget < handle
    %Reusable container for graphics used by graphicalTreeNode
    
    properties
        tree;
        axes;
        selfKey;
        boundNodeKey;
        drawIndex;
        
        inset = 3;
        downset = 1.5;
        position;
        
        group;
        expandBox;
        checkBox;
        nameText;
    end
    
    methods
        function self = graphicalTreeNodeWidget(tree)
            if nargin < 1
                return
            end

            self.tree = tree;
            tree.widgetList.append(self);
            self.selfKey = tree.widgetList.length;

            % ax set method does significant config            
            self.axes = tree.axes;
        end
        
        function buildWidgets(self)
            self.group = hggroup('Parent', self.axes);
            gTree = self.tree;
            self.nameText = text( ...
                'BackgroundColor',  'none', ...
                'Margin',           1, ...
                'Editing',          'off', ...
                'FontName',         'Courier', ...
                'FontSize',         9, ...
                'LineStyle',        '-', ...
                'LineWidth',        1, ...
                'Interpreter',      'none', ...
                'Units',            'data', ...
                'Selected',         'off', ...
                'SelectionHighlight',   'off', ...
                'VerticalAlignment',    'middle', ...
                'HorizontalAlignment',  'left', ...
                'HitTest',          'on', ...
                'ButtonDownFcn',    {@graphicalTree.respondToWidgetLabelClick, self.selfKey, gTree}, ...
                'Parent',           self.group);
            
            self.expandBox = graphicalCheckBox(self.group);
            self.expandBox.textColor = [0 0 0];
            self.expandBox.edgeColor = 'none';
            self.expandBox.backgroundColor = [1 1 1]*.75;
            self.expandBox.checkedSymbol = 'v';
            self.expandBox.uncheckedSymbol = '>';
            self.expandBox.altCheckedSymbol = ' ';          
            self.expandBox.callback = {@graphicalTree.respondToWidgetExpanderClick, self.selfKey, gTree};
            
            self.checkBox = graphicalCheckBox(self.group);
            self.checkBox.textColor = [0 0 0];
            self.checkBox.edgeColor = [1 1 1]*.25;
            self.checkBox.backgroundColor = [1 1 1]*.75;
            self.checkBox.checkedSymbol = 'F';
            self.checkBox.uncheckedSymbol = ' ';
            self.checkBox.altCheckedSymbol = 'f';
            self.checkBox.callback = {@graphicalTree.respondToWidgetCheckboxClick, self.selfKey, gTree};
        end
        
        function bindNode(self, drawCount)
            self.drawIndex = drawCount;
            node = self.tree.nodeList.getValue(self.boundNodeKey);
            self.setPositions(drawCount, node.depth);

            if ischar(node.name)
                
            else
                node.name = 'null';
            end
            set(self.nameText, ...
                'String', node.name, ...
                'Color', node.textColor, ...
                'BackgroundColor', node.textBackgroundColor);

            set(self.group, 'Visible', 'on');

            self.expandBox.isChecked = node.isExpanded;
            self.expandBox.isAlternateChecked = node.numChildren == 0;

            self.checkBox.isChecked = node.isChecked;
            self.checkBox.isAlternateChecked = self.partialSelection;
        end
        
        function unbindNode(self)
            self.boundNodeKey = [];
            self.drawIndex = [];
            set(self.group, 'Visible', 'off');
        end
        
        function setPositions(self, row, col)
            pos = [col*self.inset, (row-.5)*self.downset];
            self.position = pos;
            self.expandBox.position = pos;
            set(self.nameText, 'Position', pos+[4 0]);
            self.checkBox.position = pos+[2 0];
        end
        
        function showHighlight(self, isHighlighted)
            if isHighlighted
                set(self.nameText, 'EdgeColor', [0 0 1]);
            else
                set(self.nameText, 'EdgeColor', 'none');
            end
        end
        
        function showBusy(self, isBusy)
            if isBusy
                set(self.nameText, 'String', '...');
            elseif ~isempty(self.boundNodeKey)
                node = self.tree.nodeList.getValue(self.boundNodeKey);
                set(self.nameText, 'String', node.name);
            end
        end
        
        function isPartial = partialSelection(self)
            %                   isChecked   ~isChecked
            % no descendants    /           []
            % some descendants  /           []
            % all escendants    X           []
            node = self.tree.nodeList.getValue(self.boundNodeKey);
            isPartial = node.isChecked && node.numCheckedDescendants/node.numDescendants < 1;
        end
        
        function set.axes(self, ax)
            self.axes = ax;
            if ~isempty(self.group) && ishandle(self.group)
                set(self.group, 'Parent', ax);
            else
                self.buildWidgets;
            end
        end
    end
end