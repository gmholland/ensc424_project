function [frames, types, order] = init_frame_info()
%INIT_FRAMES Initialize an array of frame structs
%   frames = INIT_FRAMES(order) Detailed explanation goes here.

% encode/decode order by frame number
order = [1 4 2 3 7 5 6];
N_images = length(order);

% frame types
types = ['I' 'B' 'B' 'I' 'B' 'B' 'I'];
types = types(order);

fwd_ref = [0 1 1 0 4 4 0];
fwd_ref = fwd_ref(order);

back_ref = [0 4 4 0 7 7 0];
back_ref = back_ref(order);

% forward and backward weights
wf = [0 2/3 1/3 0 2/3 1/3 0];
wf = wf(order);
wb = [0 1/3 2/3 0 1/3 2/3 0];
wb = wb(order);

%%%% encode/decode order by frame number
%%%order = [1 2 3 4 5 6 7];
%%%N_images = length(order);
%%%
%%%% frame types
%%%types = ['I' 'P' 'P' 'P' 'P' 'P' 'P'];
%%%types = types(order);
%%%
%%%fwd_ref = [0 1 2 3 4 5 6];
%%%fwd_ref = fwd_ref(order);
%%%
%%%back_ref = [0 0 0 0 0 0 0];
%%%back_ref = back_ref(order);
%%%
%%%% forward and backward weights
%%%wf = [0 2/3 1/3 0 2/3 1/3 0];
%%%wf = wf(order);
%%%wb = [0 1/3 2/3 0 1/3 2/3 0];
%%%wb = wb(order);

for i = 1:N_images
    frames(i) = struct('num', order(i), 'type', types(i), 'fwd_ref', fwd_ref(i), ...
                    'back_ref', back_ref(i), 'wf', wf(i), 'wb', wb(i));
end


end
