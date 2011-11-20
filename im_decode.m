function [] = im_decode(bitstream_name, dec_name, N_images)
%IM_DECODE Summary of this function goes here.
%   [] = IM_DECODE() Detailed explanation goes here.

% perform entropy decoding
[M, N, quality, frameq_dec] = entropy_dec(bitstream_name, N_images);

% get qt and zig zag pattern based on quality
[qt, zag] = init_jpeg(quality);

% for each frame perform dequantization and inverse 8x8 block DCT
% get function handle for idct2
idct2fun = @idct2;

% initialize frameq_dec
frame_dec = zeros(M, N, N_images);

for k = 1:N_images

    % get img_dec from frameq for current frame
    imgq_dec = frameq_dec(:,:,k);

    % get DC coefficients back using the differences stored in imgq_dec
    for i = 2:M*N/64
        imgq_dec(i,1) = imgq_dec(i,1) + imgq_dec(i-1,1);
    end

    % initialize the matrix dct_mat_dec that contains the DCT coefficients for
    % each 8x8 block in matrix form
    dct_mat_dec = zeros(M,N);

    % subdivide dct_mat_dec to a 4D array Y such that
    % dct_mat_dec = [   Y(:,:,1,1)    Y(:,:,1,2)  ...  Y(:,:1,N/8)
    %               Y(:,:,2,1)    Y(:,:,2,2)  ...  Y(:,:2,N/8)
    %                  ...            ...     ...      ...
    %              Y(:,:,M/8,1)  Y(:,:,M/8,2) ... Y(:,:M/8,N/8) ];
    Y = reshape(dct_mat_dec, [8, M/8, 8, N/8]);
    Y = permute(Y, [1 3 2 4]);

    % index for which row (block) we are operating on for imgq_dec
    blkcnt = 1;

    % fill up the 8x8 subblocks of Y by dequantizing with qt and converting
    % back to a 8x8 matrix using the zig zag scan.
    for i = 1:M/8
        for j = 1:N/8

            imgq_dec_row = imgq_dec(blkcnt,:);
            % dequantize the row vector
            imgq_dec_row = imgq_dec_row.*qt;

            % convert back to 8x8 matrix from zig zag scan
            Y(:,:,i,j) = imgq_dec_row(zag);

            blkcnt = blkcnt + 1;

        end
    end

    % convert Y back to MxN matrix
    dct_mat_dec = permute(Y, [1 3 2 4]);
    dct_mat_dec = reshape(dct_mat_dec, [M N]);

    % perform 8x8 block inverse DCT to dct_mat_dec
    img_dec = blkproc(dct_mat_dec, [8 8], idct2fun);

    % round to nearest integer
    img_dec = round(img_dec);

    % write img_dec to appropriate place in frame_dec
    frame_dec(:,:,k) = img_dec;

end

% get grayscale colour map
x = (0:1:255).';
map = [x x x];

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
