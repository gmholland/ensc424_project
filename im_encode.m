function [] = im_encode(name, bitstream_name, N_images, quality)
%IM_ENCODE Run the project encoder
%   [] = IM_ENCODE(NAME, BITSTREAM_NAME, N_IMAGES, QUALITY) runs the
%   project encoder on the image set with common prefix NAME and N_IMAGES
%   different images. BITSTREAM_NAME specifies the filename to use as the
%   bitstream as the output of the encoder. 
%
%   QUALITY is a parameter that determines the rate-distortion 
%   characteristic for the output of the encoder and should be in the range
%   1 to 100. Lower values for QUALITY will result in lower image PSNR but
%   with subsequently lower bitrate and vice versa. These quality levels 
%   correspond roughly to the quality defined in the JPEG standard
%
%   See also im_decode entropy_enc

% read in the first image and use it to determine dimensions
frame = imread(strcat(name, '0.pgm'));
[M, N] = size(frame);
clear frame;

% get information about each frame, type (I, P, B), ordering etc.
frame_infos = init_frame_info(N_images);

% initialize frame_q M*N/64-by-64-by-N_images array to hold quantized DCT
% coefficients for each block within each image. Same structure used to hold
% data for I, P and B frames
frameq = zeros(M*N/64, 64, N_images);

% initialize ref to hold the reference frames for motion estimation
ref = zeros(M, N, N_images-1);

% initialize fwd_mvxs and fwd_mvys to hold forward motion vectors for each 
% block in each image
fwd_mvxs = zeros(M/8, N/8, N_images);
fwd_mvys = zeros(M/8, N/8, N_images);

% initialize back_mvxs and back_mvys to hold backward motion vectors for each 
% block in each image
back_mvxs = zeros(M/8, N/8, N_images);
back_mvys = zeros(M/8, N/8, N_images);

% get function handles for 2 dimensional DCT and IDCT
dct2fun = @dct2;
idct2fun = @idct2;

for k = 1:N_images

    % get current frame information
    frame_info = frame_infos(1,k); % frame_infos is a 1xN_images struct array

    fprintf('%2d', frame_info.num);

    % read the frame, images in sets start numbering at 0
    img = imread(strcat(name, num2str(frame_info.num-1), '.pgm'), 'pgm');

    % convert to double and centre values about 0
    img = double(img) - 128;

    % I frames - intra frame coding only
    if (strcmp(frame_info.type, 'I'))

        % perform 8x8 block DCT to image
        img = blkproc(img, [8 8], dct2fun);

        % quantize/dequantize the DCT coefficients
        imgq = quantize_DCT(img, 'jpeg', quality);
        img = dequantize_DCT(imgq, M, N, 'jpeg', quality);
 
        % store imgq in appropriate place in frameq so it can be entropy encoded
        frameq(:,:,frame_info.num) = imgq;

        % perform 8x8 block IDCT to the I frame
        img = blkproc(img, [8 8], idct2fun);

        % use this frame as the reference for next
        ref(:,:,frame_info.num) = img;

    % P frames - forward motion estimation only
    elseif (strcmp(frame_info.type, 'P'))

        % 8x8 block forward motion estimation from appropriate ref, search range 16
        [mvx, mvy] = motion_estimation(ref(:,:,frame_info.fwd_ref), img, 8, 8, 16);

        % store motion vectors so they can be entropy encoded
        fwd_mvxs(:,:,frame_info.num) = mvx;
        fwd_mvys(:,:,frame_info.num) = mvy;

        % motion compensated prediction
        pred = mc_prediction(ref(:,:,frame_info.fwd_ref), mvx, mvy);
        mcpr = img - pred;

        % perform 8x8 block DCT to the residual frame
        mcpr = blkproc(mcpr, [8 8], dct2fun);

        % quantize/dequantize the DCT coefficients of residual frame
        mcprq = quantize_DCT(mcpr, 'uniform', quality);
        mcpr = dequantize_DCT(mcprq, M, N, 'uniform', quality);

        % store mcprq in appropriate place in frameq so it can be entropy encoded
        frameq(:,:,frame_info.num) = mcprq;

        % perform 8x8 block IDCT to the residual frame
        mcpr = blkproc(mcpr, [8 8], idct2fun);

        % get the reoncstructed frame and store it as reference for later frames
        ref(:,:,frame_info.num) = pred + mcpr;

        % write out ref image for DEBUG
        ref_filename = strcat(name, num2str(frame_info.num-1), '_ref.pgm');
        imwrite(uint8(ref(:,:,frame_info.num) + 128), ref_filename, 'pgm');

        % write out mcpr image for DEBUG
        mcpr_filename = strcat(name, num2str(frame_info.num-1), '_mcpr.pgm');
        imwrite(uint8(mcpr + 128), mcpr_filename, 'pgm');

        % write out pred image for DEBUG
        pred_filename = strcat(name, num2str(frame_info.num-1), '_pred.pgm');
        imwrite(uint8(pred + 128), pred_filename, 'pgm');

    % B frames - forward and backward motion estimation
    elseif (strcmp(frame_info.type, 'B'))

        % do forward motion estimation
        % 8x8 block forward motion estimation from appropriate ref, search range 16
        [fwd_mvx, fwd_mvy] = motion_estimation(ref(:,:,frame_info.fwd_ref), img, 8, 8, 16);

        % store motion vectors so they can be entropy encoded
        fwd_mvxs(:,:,frame_info.num) = fwd_mvx;
        fwd_mvys(:,:,frame_info.num) = fwd_mvy;

        % forward motion compensated prediction
        fwd_pred = mc_prediction(ref(:,:,frame_info.fwd_ref), fwd_mvx, fwd_mvy);

        % do backward motion estimation
        % 8x8 block backward motion estimation from appropriate ref, search range 16
        [back_mvx, back_mvy] = motion_estimation(ref(:,:,frame_info.back_ref), img, 8, 8, 16);

        % store motion vectors so they can be entropy encoded
        back_mvxs(:,:,frame_info.num) = back_mvx;
        back_mvys(:,:,frame_info.num) = back_mvy;

        % backward motion compensated prediction
        back_pred = mc_prediction(ref(:,:,frame_info.back_ref), back_mvx, back_mvy);

        % take pred to be weighted average between fwd_pred and back_pred
        pred = frame_info.wb.*back_pred + frame_info.wf.*fwd_pred;

        % get prediction residual
        mcpr = img - pred;

        % perform 8x8 block DCT to the residual frame
        mcpr = blkproc(mcpr, [8 8], dct2fun);

        % quantize/dequantize the DCT coefficients of residual frame
        mcprq = quantize_DCT(mcpr, 'uniform', quality);
        mcpr = dequantize_DCT(mcprq, M, N, 'uniform', quality);

        % store mcprq in appropriate place in frameq so it can be entropy encoded
        frameq(:,:,frame_info.num) = mcprq;

        % perform 8x8 block IDCT to the residual frame
        mcpr = blkproc(mcpr, [8 8], idct2fun);

        % get the reoncstructed frame and store it as reference for later frames
        ref(:,:,frame_info.num) = pred + mcpr;

        % write out ref image for DEBUG
        ref_filename = strcat(name, num2str(frame_info.num-1), '_ref.pgm');
        imwrite(uint8(ref(:,:,frame_info.num) + 128), ref_filename, 'pgm');

        % write out mcpr image for DEBUG
        mcpr_filename = strcat(name, num2str(frame_info.num-1), '_mcpr.pgm');
        imwrite(uint8(mcpr + 128), mcpr_filename, 'pgm');

        % write out pred image for DEBUG
        pred_filename = strcat(name, num2str(frame_info.num-1), '_pred.pgm');
        imwrite(uint8(pred + 128), pred_filename, 'pgm');
    end
end

% encode the DCT coefficients for each frame
entropy_enc(M, N, frame_infos, frameq, fwd_mvxs, fwd_mvys, back_mvxs, back_mvys, ...
            bitstream_name, N_images, quality);

end
