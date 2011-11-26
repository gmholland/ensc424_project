function [frames, order] = init_frame_info(N_images)
%INIT_FRAMES Initialize an array of frame structures
%   [FRAMES, ORDER] = INIT_FRAMES(N_IMAGES) initializes and then returns
%   a 1-by-N_IMAGES struct array containing frame information based on the
%   number of images in the set N_IMAGES. Also returns ORDER, an array
%   of length N_IMAGES with the ordering of the encoder to use.
%
%   Each struct in the array contains the following fields
%       frame.num - order number for the frame within the set beginning at 1
%       frame.type - one of 'I', 'P' or 'B'
%       frame.fwd_ref - the reference image to use for forward motion
%                       estimation
%       frame.back_ref - the reference image to use for backward motion
%                        estimation
%       wf - weighting factor for forward motion compensation
%       wb - weighting factor for backward motion compensation

% encode/decode order by frame number
order = [1 2 3 4 5 6 7];
N_images = length(order);

% frame types
types = ['I' 'P' 'P' 'P' 'P' 'P' 'P'];
types = types(order);

fwd_ref = [0 1 2 3 4 5 6];
fwd_ref = fwd_ref(order);

back_ref = [0 0 0 0 0 0 0];
back_ref = back_ref(order);

% forward and backward weights
wf = [0 0 0 0 0 0 0];
wf = wf(order);
wb = [0 0 0 0 0 0 0];
wb = wb(order);

for i = 1:N_images
    frames(i) = struct('num', order(i), 'type', types(i), 'fwd_ref', fwd_ref(i), ...
                    'back_ref', back_ref(i), 'wf', wf(i), 'wb', wb(i));
end


end
