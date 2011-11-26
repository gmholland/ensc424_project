function pred = mc_prediction(prev, mvx, mvy)
%MC_PREDICTION Block-based motion-compensated prediction
%   PRED = MC_PREDICTION(PREV, MVX, MVY)
%   This function performs block-based motion-compensated prediction of
%   a frame from the previous frame, PREV, using the motion vector field 
%   described by MVX and MVY.
%
%   The predicted frame will be returned in PRED.
%
%   See also motion_estimation

% calculate size of blocks
[prev_h, prev_w] = size(prev);
[numblks_y, numblks_x] = size(mvx);
blkx = floor(prev_w/numblks_x);
blky = floor(prev_h/numblks_y);

% initialize pred to be same size as prev
pred = zeros(prev_h, prev_w);

% subdivide prev, mcpr and pred into a 4D arrays such that:
% X = [   X(:,:,1,1)             X(:,:,1,2)      ...     X(:,:1,numblks_x)
%         X(:,:,2,1)             X(:,:,2,2)      ...     X(:,:2,numblks_x)
%               ...                ...           ...              ...
%         X(:,:,numblks_y,1)  X(:,:,numblks_y,2) ... X(:,:numblks_y,numblks_x)];
pred_array = reshape(pred, [blky, numblks_y, blkx, numblks_x]);
pred_array = permute(pred_array, [1 3 2 4]);

% for each subblock in prev_array
for j = 1:numblks_y
    for i = 1:numblks_x

        % calculate index of top left corner pixel in prev_blk
        x_ind = blkx*(i-1) + 1;
        y_ind = blky*(j-1) + 1;

        % get block from prev that is displaced from current block by
        % corresponding motion vector 
        x = x_ind + mvx(j,i);
        y = y_ind - mvy(j,i); % vectors in mvy are stored with negative y pointing down

        prev_blk = prev(y:y+blky-1, x:x+blkx-1);

        % store motion compensated prev_blk in pred_array
        pred_array(:,:,j,i) = prev_blk;

    end
end

% convert pred_array and mcpr_array back to matrices
pred = permute(pred_array, [1 3 2 4]);
pred = reshape(pred, [prev_h, prev_w]);

end
