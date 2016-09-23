classdef graphicalTreeList < handle
    % This class duplicates a lot of auimodel.MapList.  But I think it
    % makes sense to leave graphicalTree independent of the auimodel.
    
    properties(SetAccess = protected)
        length;
    end
    
    properties(Hidden = true)
        containersMap;
    end
    
    methods
        function self = graphicalTreeList()
            self.containersMap = containers.Map(0, nan, 'uniformValues', false);
            self.containersMap.remove(0);
            self.length = self.containersMap.length;
        end
        
        function append(self, value)
            index = self.length+1;
            self.containersMap(index) = value;
            self.length = self.containersMap.length;
        end
        
        function value = getValue(self, index)
            if index > 0 && index <= self.length
                value = self.containersMap(index);
            else
                value = [];
            end
        end
        
        function setValue(self, index, value)
            self.containersMap(index) = value;
        end
        
        function allValues = getAllValues(self)
            allValues = self.containersMap.values;
        end
        
        function removeAllValues(self)
            for ii = 1:self.length
                self.containersMap.remove(ii);
            end
            self.length = self.containersMap.length;
        end
        
        function isContained = containsValue(self, value)
            values = self.getAllValues;
            isContained = false;
            for ii = 1:length(values)
                if isequal(values{ii}, value)
                    isContained = true;
                    return
                end
            end
        end

        function isContained = containsKey(self, key)
            isContained = self.containersMap.isKey(key);
        end
    end
end