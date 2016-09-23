function skipFlag = checkConstrainedParameters(params,settings)
%checks constrained parameters, defined by sorter (params) structure against protocol settings in
%settings struct, which is built up from epoch data
skipFlag = 0;

    constrainedParameters = fieldnames(params);
    for p = 1:length(constrainedParameters) %search for wrong-value parameters
        currentParam = params.(constrainedParameters{p});
        currentSetting = settings.(constrainedParameters{p});
        if iscell(currentParam) %cell input does greater/less/equal to constraints on numerical parameters {'>', x}, {'<=', x},...
            %also does 'any', e.g. input {'or',[20 40 60]} checks
            %any(x==[20 40 60]);
            operator = currentParam{1}; value = currentParam{2};
            
            if strcmp(operator,'any') %checks any
                if eval(['any(currentSetting == ',num2str(value),')'])
                
                else
                    skipFlag = 1;
                end
            else %check > <= etc etc.
            
                if eval(['currentSetting', operator, num2str(value)])

                else
                    skipFlag = 1;
                end
                
            end

        elseif ischar(currentParam) %checks string-valued params
            if strcmp(currentParam,currentSetting)
                
            else
                skipFlag = 1;
            end
            
        
        else %simplest check - numerical params ==
            if~(params.(constrainedParameters{p}) == eval(['settings.', constrainedParameters{p}]))
                skipFlag = 1;
            end
        end
    end
        
end