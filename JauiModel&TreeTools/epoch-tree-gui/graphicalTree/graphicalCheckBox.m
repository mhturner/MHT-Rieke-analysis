classdef graphicalCheckBox < handle
    
    properties
        parent;
        position;
        textColor;
        edgeColor;
        backgroundColor;
        
        isChecked;
        isAlternateChecked;
        
        % feval(callback{1}, self, event, callback{2:end})
        callback = [];
    end
    
    properties(Hidden=true)
        box;
        checkedSymbol = 'X';
        uncheckedSymbol = ' ';
        altCheckedSymbol = '/';
    end
    
    methods
        function self = graphicalCheckBox(parent)
            if nargin < 1
                return
            end
            self.parent = parent;
            self.box = text( ...
                'Margin',           1, ...
                'Editing',          'off', ...
                'FontName',         'Courier', ...
                'FontSize',         9, ...
                'Interpreter',      'none', ...
                'Units',            'data', ...
                'Selected',         'off', ...
                'SelectionHighlight',   'off', ...
                'HorizontalAlignment',  'left', ...
                'VerticalAlignment',    'middle', ...
                'HitTest',          'on', ...
                'ButtonDownFcn',    {@graphicalCheckBox.respondToClick, self}, ...
                'Parent',           self.parent);
            
            self.position = [0 .5];
            self.textColor = [0 0 0];
            self.edgeColor = [0 0 0];
            self.backgroundColor = 'none';
            self.isChecked = false;
            self.isAlternateChecked = false;
        end
        
        % property access methods:
        function set.parent(self, parent)
            set(self.box, 'Parent', parent);
            self.parent = parent;
        end
        function set.position(self, position)
            set(self.box, 'Position', position);
            self.position = position;
        end
        function set.textColor(self, color)
            set(self.box, 'Color', color);
            self.textColor = color;
        end
        function set.edgeColor(self, color)
            set(self.box, 'EdgeColor', color);
            self.edgeColor = color;
        end
        function set.backgroundColor(self, color)
            set(self.box, 'BackgroundColor', color);
            self.backgroundColor = color;
        end
        function set.isChecked(self, isChecked)
            if isChecked
                set(self.box, 'String', self.checkedSymbol);
            else
                set(self.box, 'String', self.uncheckedSymbol);
            end
            self.isChecked = isChecked;
        end
        function set.isAlternateChecked(self, isAlternateChecked)
            if isAlternateChecked
                set(self.box, 'String', self.altCheckedSymbol);
            end
            self.isAlternateChecked = isAlternateChecked;
        end
    end
    
    methods (Static)
        function respondToClick(obj, event, self)
            self.isChecked = ~self.isChecked;
            drawnow
            
            cb = self.callback;
            if ~isempty(cb)
                if length(cb) > 1
                    feval(cb{1}, self, event, cb{2:end});
                else
                    feval(cb{1}, self, event);
                end
            end
        end
    end
end