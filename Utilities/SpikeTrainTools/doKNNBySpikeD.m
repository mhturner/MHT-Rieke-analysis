function res = doKNNBySpikeD(inputObservations,NumNeighbors,q_cost)
% inputObservations is a cell array full of binary spike train matrices
% each entry (matrix) comes from a
% different category - each row of matrix is a different trial
% NumNeighbors (k)
% q_cost for spikeD metric

    numCats = length(inputObservations);
    
    if numCats == 1 %control, randomly assign labels
        noIterations = 500;
    else %deterministic for NumNeighbors without ties (odd for two-category)
        noIterations = 1;
    end
    
    trialsPerCategory = zeros(1,numCats);
    for c = 1:numCats
       trialsPerCategory(c) = size(inputObservations{c},1);
    end
    noTrials = min(trialsPerCategory); %no. trials per category, equal sample sizes
    if numCats==1
        noTrials = 2*floor(noTrials/2);
    end
    observations = [];
    for c = 1:numCats
       observations = cat(1,observations,inputObservations{c}(1:noTrials,:));
    end
    
    if (numCats == 1)
        noTrials = floor(trialsPerCategory/2);
        numCats = 2; %split into two cats for 50-50 control      
    end
    categories = kron(1:numCats,ones(1,noTrials)); %correct labels

    distanceMatrix = zeros(numCats*noTrials);
    for i = 1:length(categories)
        for j = 1:length(categories)
            if (i==j)
               distanceMatrix(i,j) = 0;
            else
               distanceMatrix(i,j) = spkd_with_scr(find(observations(i,:)),find(observations(j,:)),q_cost);
            end
        end
    end


    pCorrects = zeros(1,noIterations);
    for ii = 1:noIterations
        Y = categories;
        if noIterations > 1 %control case
            Y = (rand(1,numCats*noTrials)>0.5) + 1; %randomize labels in 2-cat control
        end

        distances = distanceMatrix + eye(size(distanceMatrix))*100*max(distanceMatrix(:));% -- make the "self distance" big;

        [ordered_lists labels] = sort(distances); %now it's the (:,i) distances are distances from stuff to point i...
        topys = Y(labels(1:NumNeighbors,:)); %n-neighbors (row) categories for each point (col)
        predicted = mode(topys,1); %predicted for each point
        newPCorr = sum(predicted==Y)/length(Y); %correct
        pCorrects(ii) = newPCorr;
    end
    res.pCorrect = mean(pCorrects);


