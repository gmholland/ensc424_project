function imgq = quantize_DCT(dct_frame, quality)
%QUANTIZE_DCT Quantize DCT coefficients
%   IMGQ = QUANTIZE_DCT(DCT_FRAME, FRAME_TYPE) quantizes the image frame
%   DCT_FRAME using the JPEG quantization matrix and zig-zag pattern. 
%   The quantized DCT coefficients for each block appear in each row of 
%   IMGQ. IMGQ is therefore a M*N/64 by 64 matrix where the dimensions of 
%   DCT_FRAME are M by N.

[M, N] = size(dct_frame);

% get quantization and zig-zag matrices
[qt, zag] = init_jpeg(quality);

% subdivide dct_frame to a 4D array Y such that:
% dct_frame = [   Y(:,:,1,1)    Y(:,:,1,2)  ...  Y(:,:1,N/8)
%               Y(:,:,2,1)    Y(:,:,2,2)  ...  Y(:,:2,N/8)
%                  ...            ...     ...      ...
%              Y(:,:,M/8,1)  Y(:,:,M/8,2) ... Y(:,:M/8,N/8) ];
Y = reshape(dct_frame, [8, M/8, 8, N/8]);
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
%
% TODO vectorize this operation if possible
DCdiff = zeros(1,imgq_r-1).';
for i = 2:imgq_r
    DCdiff(i-1,1) = imgq(i,1) - imgq(i-1,1);
end
imgq(2:end,1) = DCdiff;

end
