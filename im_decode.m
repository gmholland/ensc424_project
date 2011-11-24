function [] = im_decode(bitstream_name, dec_name, N_images)
%IM_DECODE Summary of this function goes here.
%   [] = IM_DECODE() Detailed explanation goes here.

% perform entropy decoding
[frame_h, frame_w, quality, frame_infos, frameq_dec, ...
    fwd_mvxs, fwd_mvys, back_mvxs, back_mvys] = entropy_dec(bitstream_name, N_images);

% for each frame perform dequantization and inverse 8x8 block DCT
% get function handle for idct2
idct2fun = @idct2;

% initialize frameq_dec
frame_dec = zeros(frame_h, frame_w, N_images);

% initialize previous_dec to store reference frames as they are decoded
ref_dec = zeros(frame_h, frame_w, N_images);

for k = 1:N_images

    % get current frame information
    frame_info = frame_infos(1,k); % frame_infos is a 1xN_images struct array

    fprintf('%2d', frame_info.num);

    % get img_dec from frameq for current frame
    imgq_dec = frameq_dec(:,:,frame_info.num);

    % I frames - intra frame coding only
    if (strcmp(frame_info.type, 'I'))

        % dequantize the DCT coefficients
        img_dec = dequantize_DCT(imgq_dec, frame_h, frame_w, 'jpeg', quality);
        
        % perform 8x8 block IDCT to dct_mat_dec
        img_dec = blkproc(img_dec, [8 8], idct2fun);

        % use this frame as the reference for next
        ref_dec(:,:,frame_info.num) = img_dec;

    % P frames - forward motion estimation only
    elseif (strcmp(frame_info.type, 'P'))

        % motion compensated prediction
        pred = mc_prediction(ref_dec(:,:,frame_info.fwd_ref), fwd_mvxs(:,:,frame_info.num), ...
                             fwd_mvys(:,:,frame_info.num));

        % dequantize the DCT coefficients of mcpr
        mcpr_dec = dequantize_DCT(imgq_dec, frame_h, frame_w, 'uniform', quality);

        % perform 8x8 block IDCT to the residual frame
        mcpr_dec = blkproc(mcpr_dec, [8 8], idct2fun);

        % get the reconstructed image
        img_dec = pred + mcpr_dec;

        % use the reconstructed as the reference frame for the next image
        ref_dec(:,:,frame_info.num) = img_dec;

        % write out ref image for DEBUG
        ref_filename = strcat(dec_name, num2str(frame_info.num-1), '_ref.pgm');
        imwrite(uint8(ref_dec(:,:,frame_info.num) + 128), ref_filename, 'pgm');

        % write out mcpr image for DEBUG
        mcpr_filename = strcat(dec_name, num2str(frame_info.num-1), '_mcpr.pgm');
        imwrite(uint8(mcpr_dec + 128), mcpr_filename, 'pgm');

        % write out pred image for DEBUG
        pred_filename = strcat(dec_name, num2str(frame_info.num-1), '_pred.pgm');
        imwrite(uint8(pred + 128), pred_filename, 'pgm');

    % B frames - forward and backward motion estimation 
    elseif (strcmp(frame_info.type, 'B'))

        % forward motion compensated prediction
        fwd_pred = mc_prediction(ref_dec(:,:,frame_info.fwd_ref), ...
                                 fwd_mvxs(:,:,frame_info.num), ...
                                 fwd_mvys(:,:,frame_info.num));
        % backward motion compensated prediction
        back_pred = mc_prediction(ref_dec(:,:,frame_info.back_ref), ...
                                  back_mvxs(:,:,frame_info.num), ...
                                  back_mvys(:,:,frame_info.num));

        % take pred to be weighted average between fwd_pred and back_pred
        pred = frame_info.wb.*back_pred + frame_info.wf.*fwd_pred;

        % dequantize the DCT coefficients of mcpr
        mcpr_dec = dequantize_DCT(imgq_dec, frame_h, frame_w, 'uniform', quality);

        % perform 8x8 block IDCT to the residual frame
        mcpr_dec = blkproc(mcpr_dec, [8 8], idct2fun);

        % get the reconstructed image
        img_dec = pred + mcpr_dec;

        % use the reconstructed as the reference frame for the next image
        ref_dec(:,:,frame_info.num) = img_dec;

        % write out ref image for DEBUG
        ref_filename = strcat(dec_name, num2str(frame_info.num-1), '_ref.pgm');
        imwrite(uint8(ref_dec(:,:,frame_info.num) + 128), ref_filename, 'pgm');

        % write out mcpr image for DEBUG
        mcpr_filename = strcat(dec_name, num2str(frame_info.num-1), '_mcpr.pgm');
        imwrite(uint8(mcpr_dec + 128), mcpr_filename, 'pgm');

        % write out pred image for DEBUG
        pred_filename = strcat(dec_name, num2str(frame_info.num-1), '_pred.pgm');
        imwrite(uint8(pred + 128), pred_filename, 'pgm');
    end

    % write img_dec to appropriate place in frame_dec so decoded images can be 
    % written later, pixel values must be integers so round them
    frame_dec(:,:,frame_info.num) = round(img_dec);

end

for k = 1:N_images
    % convert to positive numbers between 0 and 255
    frame_dec(:,:,k) = frame_dec(:,:,k) + 128;

    % write decoded images
    imfilename = strcat(dec_name, num2str(k-1), '.pgm');
    % convert to unsigned 8 bit int before writing
    im = uint8(frame_dec(:,:,k));
    imwrite(im, imfilename, 'pgm', 'Encoding', 'rawbits', 'MaxValue', 255);

end

end
