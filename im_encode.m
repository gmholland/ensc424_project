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

% perform DCT and quantization to each frame
% get quantization and zig-zag matrices
[qt, zag] = init_jpeg(quality);

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

    % subdivide dct_mat to a 4D array Y such that:
    % dct_mat = [   Y(:,:,1,1)    Y(:,:,1,2)  ...  Y(:,:1,N/8)
    %               Y(:,:,2,1)    Y(:,:,2,2)  ...  Y(:,:2,N/8)
    %                  ...            ...     ...      ...
    %              Y(:,:,M/8,1)  Y(:,:,M/8,2) ... Y(:,:M/8,N/8) ];
    Y = reshape(dct_mat, [8, M/8, 8, N/8]);
    Y = permute(Y, [1 3 2 4]);

    % initialize matrix imgq to hold quantized DCT coefficients. Each 8x8
    % subblock scanning through img from right to left, up to down gets 
    % a single 64 column row.
    imgq = zeros(M*N/64, 64);

    % index for which row (block) we are operating on for imgq
    blkcnt = 1;

    % fill up imgq rows with the quantized DCT coefficients for the 
    % appropriate 8x8 block
    for i = 1:M/8
        for j = 1:N/8

            % convert DCT coefficients to row vector using zig zag scan
            imgq_row = imgq(blkcnt,:);
            imgq_row(zag) = Y(:,:,i,j);

            % quantize the row vector
            imgq(blkcnt,:) = round(imgq_row./qt);

            blkcnt = blkcnt + 1;
        end
    end

    % get number of rows and columns in imgq
    [imgq_r, imgq_c] = size(imgq);

    % replace DC coefficients (stored in 1st col of each row in imgq) with
    % the difference between itself and previous DC coefficient
    DCdiff = zeros(1,imgq_r-1).';
    for i = 2:imgq_r
        DCdiff(i-1,1) = imgq(i,1) - imgq(i-1,1);
    end
    imgq(2:end,1) = DCdiff;

    % store imgq in appropriate place in frameq
    frameq(:,:,k) = imgq;

end

% encode the DCT coefficients on each frame
entropy_enc(M, N, frameq, bitstream_name, N_images, quality);

end
