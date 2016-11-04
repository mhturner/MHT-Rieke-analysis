function Rotated = RotateVector(Rotation, Original)

% Breaks Vector into two parts and then pastes one section to the other
% This can be used to rotate forwards or backwards in time.
% If "Rotation" > 0 then the rotation is forwards in time

pnts = length(Original);
Rotated(1:pnts) = 0;


if (Rotation > 0)
	CutOne = Original(1: (pnts - Rotation));
	CutTwo = Original(pnts - Rotation + 1: pnts);
	Rotated(1: Rotation) = CutTwo;
	Rotated(Rotation + 1: pnts) = CutOne;
end

if (Rotation < 0)
	RotationTwo = -Rotation;
	CutOne = Original(1: RotationTwo);
	CutTwo = Original((RotationTwo + 1): pnts);
	Rotated(1: (pnts - RotationTwo)) = CutTwo;
	Rotated((pnts - RotationTwo + 1): pnts) = CutOne;
end

if (Rotation == 0)
	Rotated = Original;
end
