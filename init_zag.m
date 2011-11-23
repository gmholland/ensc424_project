function zag = init_zag(frame_h, frame_w, zag_type)
%INIT_ZAG Initialize a zig zag traversal matrix
%   ZAG = INIT_ZAG(FRAME_H, FRAME_W, ZAG_TYPE) returns a matrix with elements 
%   increasing in a zig zag pattern. FRAME_H is the number of rows and FRAME_W 
%   is the number of columns in the motion vector matrix. ZAG_TYPE is one of 
%   'diagonal', 'horizontal' or 'vertical'
%
%   See also init_quantizer

zag = zeros(frame_h, frame_w);
zag(1,1) = 1;

% diagonal scan
if strcmp(zag_type, 'diagonal')
    prev_move = 'R';
    x = 2;
    y = 1;
    for i = 2:frame_h*frame_w

        zag(y,x) = i;

        if (strcmp(prev_move, 'R'))
            % if we are on top row go down and left
            if (y == 1)
                x = x - 1;
                y = y + 1;
                prev_move = 'DL';
                % if we are on bottom go up and right
            elseif (y == frame_h)
                x = x + 1;
                y = y - 1;
                prev_move = 'UR';
            end
        elseif (strcmp(prev_move, 'D'))
            % if we are on the right side go down and left
            if (x == frame_w)
                x = x - 1;
                y = y + 1;
                prev_move = 'DL';
                % if we are on the left side go up and right
            elseif (x == 1)
                x = x + 1;
                y = y - 1;
                prev_move = 'UR';
            end
        elseif (strcmp(prev_move, 'DL'))
            % if we hit the bottom go right
            if (y == frame_h)
                x = x + 1;
                prev_move = 'R';
                % if we hit left side go down
            elseif (x == 1)
                y = y + 1;
                prev_move = 'D';
                % otherwise keep going down and left
            else
                y = y + 1;
                x = x - 1;
                prev_move = 'DL';
            end
        elseif (strcmp(prev_move, 'UR'))
            % if we hit the right side go down
            if (x == frame_w)
                y = y + 1;
                prev_move = 'D';
                % if we hit the top go right
            elseif (y == 1)
                x = x + 1;
                prev_move = 'R';
                % otherwise keep going up and right
            else 
                x = x + 1;
                y = y - 1;
                prev_move = 'UR';
            end
        end
    end

% horizontal scan
else 
    x = 2;
    y = 1;
    prev_move = 'R';
    for i = 2:frame_h*frame_w

        zag(y,x) = i;

        if (strcmp(prev_move, 'R'))
            % if we hit the right side go down
            if (x == frame_w)
                y = y + 1;
                prev_move = 'D';
            % otherwise keep going right
            else 
                x = x + 1;
                prev_move = 'R';
            end
        elseif (strcmp(prev_move, 'D'))
            % if we're at the right side go left
            if (x == frame_w)
                x = x - 1;
                prev_move = 'L';
            % if we're at the left side go right
            elseif (x == 1)
                x = x + 1;
                prev_move = 'R';
            % otherwise keep going down
            else 
                y = y + 1;
                prev_move = 'D';
            end
        elseif (strcmp(prev_move, 'L'))
            % if we hit the left side go down
            if (x == 1)
                y = y + 1;
                prev_move = 'D';
            % otherwise keep going left
            else 
                x = x - 1;
                prev_move = 'L';
            end
        end
    end
end

% the vertical scan is the same as the transpose of horizontal scan
if strcmp(zag_type, 'vertical')
    zag = zag.';
end

end
