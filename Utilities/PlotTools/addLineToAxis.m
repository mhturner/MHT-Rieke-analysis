function addLineToAxis(xData,yData,nameString,parent,color,lineStyle,markerStyle)
if nargin < 5
   color = 'k';
   lineStyle = '-';
   markerStyle = 'o';
   
end
    temp = line(xData,yData,'Parent',parent);
    set(temp,'LineStyle',lineStyle,'Marker',markerStyle,'Color',color,'DisplayName',nameString);

end