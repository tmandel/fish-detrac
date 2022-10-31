function [h area labels] = invhist(im,weightoff)
%function [hist area labels] = invhist(im,weightoff)
% given an image, get an invariant color histogram
%INPUT
% im        <-> image
% weightoff <-> 0: create invariant histogram  1: create traditional
%               histogram (default 0)
% rez       <-> number of bins in each color dimension
%               (deault 5)
% OUTPUT
% h         <-> 3d array containing the histogram
% area      <-> shows relative contributions of different image pixels
% labels    <-> to which 'label' does each pixel color correspond?

if nargin<2
    weightoff = 0;
end
if nargin < 3
    rez = 32;
end

im = double(im);
im = im/max(im(:));

toohigh = find(im>1);
im(toohigh) = 1;
toolow  = find(im<0);
im(toolow) = 0;

[ly lx lz] = size(im);
filt = [-1 0 1];

gim = .5*im(:,:,3) + ...
      .5*im(:,:,2);
fim = im(:,:,1);

myim1 = im(:,:,1);
myim2 = im(:,:,2);
myim3 = im(:,:,3);

if weightoff
    fx = 0*fim;
    fy = 0*fim;
    gx = 0*fim;
    gy = 0*fim;
else
    fx = conv2(fim,filt ,'same');
    gx = conv2(gim,filt ,'same');
    fy = conv2(fim,filt','same');
    gy = conv2(gim,filt','same');
    
end

test = (0==conv2(double(max(isnan(sum(im,3)),(0==sum(im,3)))),ones(5),'same'));
killa = zeros(ly,lx);
killa(6:end-5,6:end-5) = test(6:end-5,6:end-5);


ok = killa .* not(isnan(myim1.*myim2.*myim3)) .* (myim1.*myim2.*myim3 > 0) .* ...
    not(isnan(fx)) .* not(isnan(fy)) .* not(isnan(gx)) .* not(isnan(gy));

area   = 0*myim1;
labels = 0*myim1;

h = zeros(rez,rez,rez);
for i=1:ly
    for j=1:lx
        if ok(i,j)
            place_bin1 = max(1,ceil(rez*myim1(i,j)));
            place_bin2 = max(1,ceil(rez*myim2(i,j)));
            place_bin3 = max(1,ceil(rez*myim3(i,j)));
            
            weight = fx(i,j)*gy(i,j)-fy(i,j)*gx(i,j);
            weight = abs(weight);
            if weightoff
                weight = 1;
            end
            area(i,j) = weight;
            labels(i,j) = (place_bin3-1)*rez*rez + (place_bin2-1)*rez + place_bin1;
            
            h(place_bin1,place_bin2,place_bin3) = h(place_bin1,place_bin2,place_bin3)+weight;
            
        end
    end
end

