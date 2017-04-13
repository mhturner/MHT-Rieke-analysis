function initFig(figObject,xString,yString)

    set(figObject,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    set(get(figObject,'XLabel'),'String',xString)
    set(get(figObject,'YLabel'),'String',yString)
    set(gcf, 'WindowStyle', 'docked')
end