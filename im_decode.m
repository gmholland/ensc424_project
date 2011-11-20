function [] = im_decode(bitstream_name, dec_name, N_images)
%IM_DECODE Summary of this function goes here.
%   [] = IM_DECODE() Detailed explanation goes here.

% perform entropy decoding
[frame_h, frame_w, quality, frameq_dec] = entropy_dec(bitstream_name, N_images);

% for each frame perform dequantization and inverse 8x8 block DCT
% get function handle for idct2
idct2fun = @idct2;

% initialize frameq_dec
frame_dec = zeros(frame_h, frame_w, N_images);

for k = 1:N_images

    % get img_dec from frameq for current frame
    imgq_dec = frameq_dec(:,:,k);

    % dequantize the DCT coefficients
    dct_mat_dec = dequantize_DCT(imgq_dec, quality, frame_h, frame_w);

    % perform 8x8 block inverse DCT to dct_mat_dec
    img_dec = blkproc(dct_mat_dec, [8 8], idct2fun);

    % round to nearest integer
    img_dec = round(img_dec);

    % write img_dec to appropriate place in frame_dec
    frame_dec(:,:,k) = img_dec;

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
