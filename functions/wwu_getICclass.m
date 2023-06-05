function [classnum, indx] = wwu_getICclass(weights, threshold)


if size(weights,1) > size(weights,2)
    weights = weights';
end

nclasses = size(weights,1);

%get the maximum weight for each components
[~, i] = max(weights);
%vectorize the index
j = (0:length(i)-1) * nclasses;
ii = i + j;

%assign the category only for those that exceed the threshold
weights(ii(weights(ii)>threshold)) = 1;

%set all others to zero
weights(weights < 1) = 0;

%thresh_w = thresh_w';
c = 1:nclasses;
c = repmat(c', 1,size(weights,2));

[classnum, indx] = sort(sum(weights .* c)');
