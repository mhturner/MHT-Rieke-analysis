function Ind = getThresCross(V,th,dir)
%dir 1 = up, -1 = down

Vorig = V(1:end-1);
Vshift = V(2:end);

if dir>0
    Ind = find(Vorig<th & Vshift>=th) + 1;
else
    Ind = find(Vorig>=th & Vshift<th) + 1;
end


