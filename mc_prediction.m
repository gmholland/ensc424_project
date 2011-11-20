function [mcpr, pred] = mc_prediction(prev, curr, mvx, mvy)
%MC_PREDICTION Block-based motion-compensated prediction
%   [MCPR, PRED] = MC_PREDICTION(PREV, CURR, MVX, MVY)
%   This function performs block-based motion-compensated prediction of
%   the current frame CURR from the previous frame, PREV, using the motion
%   vector field described by MVX and MVY.
%
%   The predicted frame will be return in PRED and the motion-compensated
%   prediction residual (MCPR) will be returned in MCPR.

% calculate size of blocks
[curr_h, curr_w] = size(curr);
[numblks_y, numblks_x] = size(mvx);
blkx = floor(curr_w/numblks_x);
blky = floor(curr_h/numblks_y);

% initialize mcpr and pred to be same size as curr
mcpr = zeros(curr_h, curr_w);
pred = zeros(curr_h, curr_w);

% subdivide curr, mcpr and pred into a 4D arrays such that:
% X = [   X(:,:,1,1)             X(:,:,1,2)      ...     X(:,:1,numblks_x)
%         X(:,:,2,1)             X(:,:,2,2)      ...     X(:,:2,numblks_x)
%               ...                ...           ...              ...
%         X(:,:,numblks_y,1)  X(:,:,numblks_y,2) ... X(:,:numblks_y,numblks_x)];
curr_array = reshape(curr, [blky, numblks_y, blkx, numblks_x]);
curr_array = permute(curr_array, [1 3 2 4]);
mcpr_array = reshape(mcpr, [blky, numblks_y, blkx, numblks_x]);
mcpr_array = permute(mcpr_array, [1 3 2 4]);
pred_array = reshape(pred, [blky, numblks_y, blkx, numblks_x]);
pred_array = permute(pred_array, [1 3 2 4]);

% for each subblock in curr_array
for j = 1:numblks_y
    for i = 1:numblks_x

        % extract the block from curr_array
        curr_blk = curr_array(:,:,j,i);

        % calculate index of top left corner pixel in curr_blk
        x_ind = blkx*(i-1) + 1;
        y_ind = blky*(j-1) + 1;

        % get block from prev that is displaced from current block by
        % corresponding motion vector 
        x = x_ind + mvx(j,i);
        y = y_ind - mvy(j,i); % vectors in mvy are stored with negative y pointing down

        prev_blk = prev(y:y+blky-1, x:x+blkx-1);

        % store motion compensated prev_blk in pred_array
        pred_array(:,:,j,i) = prev_blk;

        % store residual
        mcpr_array(:,:,j,i) = curr_blk - prev_blk;

    end
end

% convert pred_array and mcpr_array back to matrices
pred = permute(pred_array, [1 3 2 4]);
pred = reshape(pred, [curr_h, curr_w]);
mcpr = permute(mcpr_array, [1 3 2 4]);
mcpr = reshape(mcpr, [curr_h, curr_w]);

end
