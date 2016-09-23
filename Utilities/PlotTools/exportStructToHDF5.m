function exportStructToHDF5(s, fileName, dataRoot, options)
% Export a 1x1 struct to HDF5 file. Each field of s is written as a dataset
% of the same name.
%
% exportStructToHDF5(s, fileName, dataRoot, options)
%
% s: struct
% fielName: hdf5 filename
% dataRoot: hdf5 root to put s under.
% options:
%   .overwrite = True to overwrite fileName (default = False)
%   .prefix: prefix to append to field names before adding to HDF5
%   database (default = '')
	
	ops = struct('overwrite',0, 'prefix', '');
	if(nargin >= 4)
		ops = mergeStruct(ops, options);
	end
	
	f=fopen(fileName, 'r');
	if(f ~= -1)
		fileExists = true;
		fclose(f);
	else
		fileExists = false;
	end
	
	fNames = fieldnames(s);
	
	if(ops.overwrite | ~fileExists)
		wrMode = 'overwrite';
	else
		wrMode = 'append';
	end
	
	for i = 1:length(fNames)
		if(i>1)
			cWrMode = 'append';
		else
			cWrMode = wrMode;
		end
		
		hdf5write(fileName, strcat(dataRoot, '/', ops.prefix, fNames{i}), s.(fNames{i}), 'WriteMode', cWrMode);
	end
	
end