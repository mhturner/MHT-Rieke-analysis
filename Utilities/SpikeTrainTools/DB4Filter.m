function fdata = DB4Filter(data, maxLevel)
% fdata = DB4Filter(data, maxlevel)
% 
% This function uses the Daubechies(4) wavelet to highpass filter the data.
%
% data	- an N x M array of continuously-recorded raw data
%		where N is the number of channels, each containing M samples
% maxLevel - the level of decomposition to perform on the data. This integer
%		implicitly defines the cutoff frequency of the filter.
% 		Specifically, cutoff frequency = samplingrate/(2^(maxLevel+1))

[numwires, numpoints] = size(data);
fdata = zeros(numwires, numpoints);

for i=1:numwires % For each wire
    % Decompose the data
    [c,l] = DB4Dec(data(i,:), maxLevel);
    % Zero out the approximation coefficients
    c(1:l(1)) = 0;
    % then reconstruct the signal, which now lacks low-frequency components
    fdata(i,:) = DB4Rec(c, l);
end

end

function [c,l] = DB4Dec(x, n)


% Define the lowpass forward filter.
Lo_D = [-0.010597401784997, 0.032883011666983, 0.030841381835987, -0.187034811718881,...
    -0.027983769416984, 0.630880767929590, 0.714846570552542, 0.230377813308855];
% Define the highpass forward filter.
Hi_D = [-0.230377813308855, 0.714846570552542, -0.630880767929590, -0.027983769416984,...
    0.187034811718881, 0.030841381835987, -0.032883011666983, -0.010597401784997];

% Initialization.
s = size(x); x = x(:)'; % row vector
c = [];
l = zeros(1,n+2);
if isempty(x) , return; end

l(end) = length(x);
for k = 1:n
    [x,d] = fastDWT(x,Lo_D,Hi_D); % decomposition
    c     = [d c];            % store detail
    l(n+2-k) = length(d);     % store length
end

% Last approximation.
c = [x c];
l(1) = length(x);

if s(1)>1, c = c'; l = l'; end

end

function [a,d] = fastDWT(x, Lo_D, Hi_D)
    lf = length(Lo_D);
    lx = length(x);
    shift = 0;
    
    % Extend, Decompose &  Extract coefficients.
    first = 2-shift;
    lenEXT = lf/2; last = 2*ceil(lx/2);
    y = extendData('1D','sym',x,lenEXT);

    % Compute coefficients of approximation.
    z = conv2(y(:)',Lo_D(:)','valid'); 
    a = z(first:2:last);

    % Compute coefficients of detail.
    z = conv2(y(:)',Hi_D(:)','valid'); 
    d = z(first:2:last);
end

function a = DB4Rec(c,l)
% Define the lowpass reverse filter.
Lo_R = [0.230377813308855,0.714846570552542,0.630880767929590,-0.027983769416984,...
    -0.187034811718881,0.030841381835987,0.032883011666983,-0.010597401784997];
% Define the highpass reverse filter.
Hi_R = [-0.010597401784997,-0.032883011666983,0.030841381835987,0.187034811718881,...
    -0.027983769416984,-0.630880767929590,0.714846570552542,-0.230377813308855];

rmax = length(l);
nmax = rmax-2;
n = 0;

% Initialization.
a = c(1:l(1));

% Iterated reconstruction.
imax = rmax+1;
for p = nmax:-1:n+1
    d = DetermineCoefs(c,l,p);                % extract detail
    a = fastInvDWT(a,d,Lo_R,Hi_R,l(imax-p));
end

end

function varargout = DetermineCoefs(coefs,longs,levels)
% Check arguments.
nmax = length(longs)-2;
cellFLAG = false;
if nargin>2
    if isnumeric(levels)
        if (any(levels < 1)) || (any(levels > nmax) ) || ...
            any(levels ~= fix(levels))
            error(message('Invalid level value'));
        end
        cellFLAG = (nargin>3);
    else
        cellFLAG = true;
        levels = 1:nmax;
    end   
else
    levels = nmax;
end

first = cumsum(longs)+1;
first = first(end-2:-1:1);
longs = longs(end-1:-1:2);
last  = first+longs-1;
nblev = length(levels);
tmp   = cell(1,nblev);
for j = 1:nblev
    k = levels(j);
    tmp{j} = coefs(first(k):last(k));
end

if nargout>0
   if (nargout==1 && nblev>1) || cellFLAG
       varargout{1} = tmp;
   else
       varargout = tmp;
   end
end

end

function x = fastInvDWT(a, d, Lo_R, Hi_R, s)
% Get the lowpass filter
yLo = a;
yLo = conv2(dyadicUpSample(yLo,0), Lo_R);
yLo = keepData(yLo,s,'c',0);

% Get the lowpass filter
yHi = d;
yHi = conv2(dyadicUpSample(yHi,0), Hi_R);
yHi = keepData(yHi,s,'c',0);

% Reconstructed Approximation and Detail.
x = yLo + yHi;
end

function y = dyadicUpSample(x,varargin)

% Special case.
if isempty(x) , y = []; return; end

def_evenodd = 1;
nbInVar = nargin-1;
[r,c]   = size(x);
evenLEN = 0;
if min(r,c)<=1
    dim = 1;
    switch nbInVar
        case {1,3}
           if ischar(varargin{1}) , dim = 2; end
        case 2
           if ischar(varargin{1}) || ischar(varargin{2}) , dim = 2; end
    end
else
    dim = 2;
end
if dim==1
    switch nbInVar
        case 0
            p = def_evenodd;
        case {1,2}
            p = varargin{1};
            if nbInVar==2 , evenLEN = 1; end
        otherwise
            error(message('Invalid input'));
    end
    rem2    = rem(p,2);
    if evenLEN , addLEN = 0; else addLEN = 2*rem2-1; end
    l = 2*length(x)+addLEN;
    y = zeros(1,l);
    y(1+rem2:2:l) = x;
    if r>1, y = y'; end
else
    switch nbInVar
        case 0 , p = def_evenodd; o = 'c';
        case 1
            if ischar(varargin{1})
                p = def_evenodd; o = lower(varargin{1}(1));
            else
                p = varargin{1}; o = 'c';
            end
        otherwise
            if ischar(varargin{1})
                p = varargin{2}; o = lower(varargin{1}(1));
            else
                p = varargin{1}; o = lower(varargin{2}(1));
            end
    end
    if nbInVar==3 , evenLEN = 1; end
    rem2 = rem(p,2);
    if evenLEN , addLEN = 0; else addLEN = 2*rem2-1; end
    switch o
        case 'c'
            nc = 2*c+addLEN;
            y  = zeros(r,nc);
            y(:,1+rem2:2:nc) = x;

        case 'r'
            nr = 2*r+addLEN;
            y  = zeros(nr,c);
            y(1+rem2:2:nr,:) = x;

        case 'm'
            nc = 2*c+addLEN;
            nr = 2*r+addLEN;
            y  = zeros(nr,nc);
            y(1+rem2:2:nr,1+rem2:2:nc) = x;

        otherwise
            error(message('Invalid argument value...'));
    end
end
end

function y = keepData(x,len,varargin)

% Check arguments.
nbIn = nargin;

y = x;
sx = length(x);
ok = (len >= 0) && (len < sx);
if ~ok , return; end

if nbIn<3 , OPT = 'c'; else OPT = lower(varargin{1}); end
if ischar(OPT)
    switch OPT
        case 'c'
            if nbIn<4 , side = 0; else side = varargin{2}; end
            d = (sx-len)/2;
            switch side
                case {'u','l','0',0} , 
                    first = 1+floor(d); last = sx-ceil(d);
                case {'d','r','1',1} , 
                    first = 1+ceil(d);  last = sx-floor(d);
            end

        case {'l','u'} , first = 1;        last = len;
        case {'r','d'} , first = sx-len+1; last = sx;
    end
else
    first = OPT; last = first+len-1;
    if (first ~= fix(first)) || (first<1) || (last>sx)
        error(message('Invalid argument value...'));
    end
end
y = y(first:last);
end
