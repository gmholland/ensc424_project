function [mvx, mvy] = motion_estimation(prev, curr, blkx, blky, search_range)
%MOTION_ESTIMATION Block-based motion estimation
%   [MVX, MVY] = MOTION_ESTIMATION(PREV, CURR, BLKX, BLKY, SEARCH_RANGE) 
%   This function will perform block-based motion estimation between the
%   previous frame, PREV, and the current frame CURR. The blocks used in
%   the motion estimation have BLKY rows and BLKX columns. 
%
%   Parameter SEARCH_RANGE specifies the range over which the block in 
%   the current frame will search for the best matching block in the 
%   previous frame. For example, if search_range = 16, then the best
%   matching block will be searched over +/-16 pixels (horizontally 
%   and vertically) relative to the position of the current block.
%
%   MVX and MVY store the x-component and y-component of the motion
%   vectors respectively.

% get curr frame size
[curr_h, curr_w] = size(curr);

% calculate dimensions of mvx and mvy, initialize to zeros
numblks_x = floor(curr_w/blkx);
numblks_y = floor(curr_h/blky);
mvx = zeros(numblks_y, numblks_x);
mvy = zeros(numblks_y, numblks_x);

% subdivide current frame to a 4D array Y such that:
% curr = [   Y(:,:,1,1)           Y(:,:,1,2)     ...     Y(:,:1,numblks_x)
%            Y(:,:,2,1)           Y(:,:,2,2)     ...     Y(:,:2,numblks_x)
%               ...                  ...         ...      ...
%         Y(:,:,numblks_y,1)  Y(:,:,numblks_y,2) ... Y(:,:numblks_y,numblks_x)];
Y = reshape(curr, [blky, numblks_y, blkx, numblks_x]);
Y = permute(Y, [1 3 2 4]);

% for each subblock in Y
for j = 1:numblks_y
    for i = 1:numblks_x

        % extract the block from Y
        curr_blk = Y(:,:,j,i);

        % calculate index of top left corner pixel in curr_blk
        x_ind = blkx*(i-1) + 1;
        y_ind = blky*(j-1) + 1;

        % calculate allowable search range given the index of top left
        % corner pixel and search_range
        if (x_ind - search_range < 1)
            x_min = 1;
        else
            x_min = x_ind - search_range;
        end
        if ((x_ind + search_range) > (curr_w - blkx + 1))
            x_max = curr_w - blkx + 1;
        else
            x_max = x_ind + search_range;
        end
        if (y_ind - search_range < 1)
            y_min = 1;
        else
            y_min = y_ind - search_range;
        end
        if ((y_ind + search_range) > (curr_h - blky + 1))
            y_max = curr_h - blky + 1;
        else
            y_max = y_ind + search_range;
        end

        % search the prev frame over the search range and take sum of
        % absolute differences (SAD)
        minSAD = inf;
        minSAD_x = x_ind;
        minSAD_y = y_ind;

        for y = y_min:y_max
            for x = x_min:x_max

                % extract block from previous frame
                %[i, j, x, y]
                prev_blk = prev(y:y+blky-1, x:x+blkx-1);

                % take SAD between prev_blk and curr_blk
                SAD = sum(sum(abs(curr_blk - prev_blk))); 

                % take minimum SAD
                if (SAD < minSAD) 
                    minSAD = SAD;
                    minSAD_x = x;
                    minSAD_y = y;
                end
            end
        end

        % set mvx and mvy for the block
        mvx(j,i) = minSAD_x - x_ind;
        mvy(j,i) = -(minSAD_y - y_ind); % motion vectors have cartesian signs

    end
end

end
