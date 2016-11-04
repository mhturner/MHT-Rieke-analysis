function OutputList = ShuffleList(InputList)
%
% 	OutputList = ShuffleList(InputList)
%
%	This is a generalization of "randperm.m".  You can give
% 	it a list of numbers that does not start with "1", and it 
%	will shuffle the list.

NumPos = length(InputList);
RandomPos = randperm(NumPos);
OutputList = InputList(RandomPos);
