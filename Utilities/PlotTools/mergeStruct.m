function s = mergeStruct(A, B)
% Merge two structs
%
% s = mergeStruct(A, B)
%
% Fields in B are copied to A, overwriting fields with the same name
% (if they exist)
	
	s = A;
	
	f = fieldnames(B);
	for i = 1:length(f)
		s.(f{i}) = B.(f{i});
	end
end