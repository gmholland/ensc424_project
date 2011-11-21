function [] = im_encode(name, bitstream_name, N_images, quality)
%IM_ENCODE Summary of this function goes here.
%   [] = IM_ENCODE(INPUT_ARGS) Detailed explanation goes here.

% read in the first image and use it to determine dimensions
frame = imread(strcat(name, '0.pgm'));
[M, N] = size(frame);
clear frame;

% initialize frame_q M*N/64-by-64-by-N_images array to hold quantized DCT
% coefficients for each block within each image
frameq = zeros(M*N/64, 64, N_images);

% initialize prev to hold the reference frames for motion estimation
prev = zeros(M, N, N_images-1);

% initialize mvx and mvy to hold motion vectors for each block in each image
mvxs = zeros(M/8, N/8, N_images-1);
mvys = zeros(M/8, N/8, N_images-1);

% get function handles for 2 dimensional DCT and IDCT
dct2fun = @dct2;
idct2fun = @idct2;

for k = 1:N_images

    fprintf('%2d', k);

    % read the frame, images in sets start numbering at 0
    img = imread(strcat(name, num2str(k-1), '.pgm'), 'pgm');

    % convert to double and centre values about 0
    img = double(img) - 128;

    % I frame
    if (k == 1)

        % perform 8x8 block DCT to image
        img = blkproc(img, [8 8], dct2fun);

        % quantize/dequantize the DCT coefficients
        imgq = quantize_DCT(img, 'jpeg', quality);
        img = dequantize_DCT(imgq, M, N, 'jpeg', quality);
 
        % store imgq in appropriate place in frameq so it can be entropy encoded
        frameq(:,:,k) = imgq;

        % perform 8x8 block IDCT to the I frame
        img = blkproc(img, [8 8], idct2fun);

        % use this frame as the reference for next
        prev(:,:,k) = img;

    % only do motion estimation and mc prediction for P frames
    else

        % motion estimation
        [mvx, mvy] = motion_estimation(prev(:,:,k-1), img, 8, 8, 16);

        % store motion vectors so they can be entropy encoded
        mvxs(:,:,k-1) = mvx;
        mvys(:,:,k-1) = mvy;

        % motion compensated prediction
        pred = mc_prediction(prev(:,:,k-1), mvx, mvy);
        mcpr = img - pred;

        % perform 8x8 block DCT to the residual frame
        mcpr = blkproc(mcpr, [8 8], dct2fun);

        % quantize/dequantize the DCT coefficients of residual frame
        mcprq = quantize_DCT(mcpr, 'uniform');
        mcpr = dequantize_DCT(mcprq, M, N, 'uniform');

        % store mcprq in appropriate place in frameq so it can be entropy encoded
        frameq(:,:,k) = mcprq;

        % don't need to use the last frame to predict
        if (k ~= N_images)

            % perform 8x8 block IDCT to the residual frame
            mcpr = blkproc(mcpr, [8 8], idct2fun);

            % get the reoncstructed frame and use it as the reference frame
            % for the next image
            prev(:,:,k) = pred + mcpr;
        end

    end

end

% encode the DCT coefficients for each frame
entropy_enc(M, N, frameq, mvxs, mvys, bitstream_name, N_images, quality);

end
