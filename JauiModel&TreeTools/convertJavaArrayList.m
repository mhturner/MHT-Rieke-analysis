function outArray = convertJavaArrayList(inputArray)
%MHT 9/19/14
    jArray = inputArray.toArray;

    outArray = zeros(1,length(jArray));
    for i = 1:length(jArray)
        outArray(i) = jArray(i);
    end

end