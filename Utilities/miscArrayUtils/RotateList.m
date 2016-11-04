function Rotated =  RotateList(Rotation, Original)

Rotated(1:length(Original)) = 0;

if (Rotation > 0)
	for cnt=1:length(Original)
		pos = cnt + Rotation;
		if (pos > length(Original))
			pos = pos - length(Original);
		end
		Rotated(cnt) = Original(pos);
	end
end

if (Rotation <= 0)
	for cnt=1:length(Original)
		pos = cnt + Rotation;
		if (pos <= 0)
			pos = length(Original) + pos - 1;
		end
		Rotated(cnt) = Original(pos);
	end
end
