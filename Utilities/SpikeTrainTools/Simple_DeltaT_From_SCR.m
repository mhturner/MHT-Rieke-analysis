function [DeltaT, tli_spike, tlj_spike]=Simple_DeltaT_From_SCR(scr,cost,tli,tlj)

%
% Quantifies DeltaT (in ms) between pairs of spikes chosen by spike d
% algorithim. Function requires : (1) the scr matrix that comes from the spkd calculation, (2) the
% assigned cost for shifting spikes, and (3/4) the vectors containing the spikes times for each of two
% spikes trains (tli, tlj).
%
% GJM 3/06
%

[scr_rows,scr_columns]=size(scr);                                                       % how many rows/columns are in the scr matrix
for i=1:scr_rows;                                                                                           % for each row of the scr matrix
    for j=1:scr_columns;                                                                                    % for each column of the scr matrix 
        raw_subtraction(i,j)=scr(i,j)-((i-1)+(j-1));                                                  % compute the subtraction matrix (how different each value is than it would be if the remove/replace operation had been performed)
    end
end

scale_factor=cost*.1;                                                                            %                                           
subtraction=raw_subtraction./scale_factor;                                        % this line, and the line either side of it, reduces the chance of small decimals messing up the min command below
subtraction=round(subtraction);                                                              %

pair=1;
column=2;                                                                                                     % start in the second column of the subtraction matrix (the first is composed entirely of zeros)
if scr_rows<=scr_columns;                                                                          % if there are less rows than columns
    while column<scr_columns;                                                                      % while the present column is less than the total columns -1 
        [pre_a,pre_b]=min(subtraction(:,column-1));                                        % what is the minimum value in the previous column
        [a,b]=min(subtraction(:,column));                                                              % what is the minimum value in this column, and where does it occur
        [a1,b1]=min(subtraction(:,column+1));                                                       % what is the minimum value in the next column, and where does it occur
        if b1==b;                                                                                                             % if the minimum in the next column occurs in the same row as the current column...  (you can 'save' more by just moving over, so....)
            column=column+1;                                                                                        % ... move to the next column
        elseif a1==a;                                                                                                         % if the minimum in the next column == the minimum in the current column... (you arent' saving anything, so you're just removing/replacing... so....)
            column=column+1;                                                                                            % .... move to the next column 
       elseif pre_a==a                                                                                                         % if the minimum in the previous column occurs in the same row as the current column... (don't want to keep Delta T from current pairing when you move to next column)
           column=column+1;                                                                                                 %... move to the next column       
       elseif b1>b && a1<a;                                                                                                      % if the minimum in the next column is (1) in a lower row and (2) more negative  
           DeltaT(pair)=abs(tli(b-1)-tlj(column-1));                                                                 % calculate the DeltaT between the indexed spikes 
           tli_spike(pair)=b-1;                                                                                                      % this spike in tli forms one half of the pair
           tlj_spike(pair)=column-1;                                                                                             % this spike in tlj forms the other half of the pair
           pair=pair+1;
           column=column+1;
        end
        clear a* b*
    end
elseif scr_rows>scr_columns;
     subtraction=subtraction';
     while column<scr_rows;
        [pre_a,pre_b]=min(subtraction(:,column-1));
        [a,b]=min(subtraction(:,column));
        [a1,b1]=min(subtraction(:,column+1));
        if b1==b;
            column=column+1;
            display('a')
        elseif a1==a;
            column=column+1;
            display('b')
        elseif pre_a==a;
            column=column+1;
            display('c')
        elseif b1>b && a1<a;   
            DeltaT(pair)=abs(tlj(b-1)-tli(column-1));
            tlj_spike(pair)=b-1;
            tli_spike(pair)=column-1;
            pair=pair+1;
            column=column+1;
            display('d')
        end
        clear a* b*
     end
end
     



% 
% % 
% %this version works except high delta values
% %
% 
% pair=1;
% column=2;
% 
% if scr_rows<=scr_columns;
%     while column<scr_columns;
%         [a,b]=min(subtraction(:,column));
%         [a1,b1]=min(subtraction(:,column+1));
%         if b1==b;
%             column=column+1;
%         elseif b1>b                                                 
%             DeltaT(pair)=abs(tli(b-1)-tlj(column-1));
%             tli_spike(pair)=b-1;
%             tlj_spike(pair)=column-1;
%             pair=pair+1
%             column=column+1
%         end
%         clear a* b*
%     end
% elseif scr_rows>scr_columns
%      subtraction=subtraction';
%      while column<scr_rows;
%         [a,b]=min(subtraction(:,column))
%         [a1,b1]=min(subtraction(:,column+1))
%         if b1==b
%             column=column+1;
%         elseif b1>b                                                                      
%             DeltaT(pair)=abs(tli(b-1)-tlj(column-1));
%             tli_spike(pair)=b-1;
%             tlj_spike(pair)=column-1;
%             pair=pair+1;
%             column=column+1;
%         end
%         clear a* b*
%      end
% end

    
    


    
        
        