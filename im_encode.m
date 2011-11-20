function [] = im_encode(name, bitstream_name, N_images, quality)
%IM_ENCODE Summary of this function goes here.
%   [] = IM_ENCODE(INPUT_ARGS) Detailed explanation goes here.

% read in the first image to get the resolution for the set
frame = imread(strcat(name, '0.pgm'));
[M, N] = size(frame);

% create  zero M-by-N-by-N_images array
frame = zeros(M, N, N_images);

% read in the rest of the images given name and N_images
% note: images in sets start numbering at 0
for k = 1:N_images
    frame(:,:,k) = imread(strcat(name, num2str(k-1), '.pgm'), 'pgm');

    % convert to double and centre values about 0
    frame(:,:,k) = double(frame(:,:,k)) - 128;
end

% initialize frame_q M*N/64-by-64-by-N_images array to hold quantized DCT
% coefficients for each block within each image
frameq = zeros(M*N/64, 64, N_images);

% get function handle for 2 dimensional DCT
dct2fun = @dct2;

for k = 1:N_images
    % get image from frame
    img = frame(:,:,k);
    
    % perform 8x8 block DCT to image
    dct_mat = blkproc(img, [8 8], dct2fun);

    % quantize the DCT coefficients
    imgq = quantize_DCT(dct_mat, quality);

    % store imgq in appropriate place in frameq
    frameq(:,:,k) = imgq;

end

% encode the DCT coefficients on each frame
entropy_enc(M, N, frameq, bitstream_name, N_images, quality);

end
