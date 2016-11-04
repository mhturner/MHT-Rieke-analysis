function Rotated = RotateMatrix(Rotation, Original)
%
%	Rotated = RotateMatrix(Rotation, Original)
%
% Input is a matrix, it breaks each row of the matrix
% into two parts and then pastes one section to the other.
% This can be used to rotate forwards or backwards in time.
% If "Rotation" > 0 then the rotation is forwards in time
%  Created: GDF 09/10/01

[NumEpoch, timepts] = size(Original);
Rotated = zeros(NumEpoch, timepts);

for epoch = 1:NumEpoch
		if (Rotation(epoch) > 0)
		CutOne = Original(epoch, 1: (timepts - Rotation(epoch)));
		CutTwo = Original(epoch, timepts - Rotation(epoch) + 1: timepts);
		Rotated(epoch, 1: Rotation(epoch)) = CutTwo;
		Rotated(epoch, Rotation(epoch) + 1: timepts) = CutOne;
	end

	if (Rotation(epoch) < 0)
		RotationTwo = -Rotation(epoch);
		CutOne = Original(epoch, 1:RotationTwo);
		CutTwo = Original(epoch, (RotationTwo + 1): timepts);
		Rotated(epoch, 1: (timepts - RotationTwo)) = CutTwo;
		Rotated(epoch, (timepts - RotationTwo + 1): timepts) = CutOne;
	end

	if (Rotation(epoch) == 0)
		Rotated(epoch,:) = Original(epoch,:);
	end
end
