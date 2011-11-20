function dct_mat_dec = dequantize_DCT(imgq_dec, quality, M, N)
%DEQUANTIZE_DCT Dequantize DCT coefficients
%   DCT_MAT_DEC = DEQUANTIZE_DCT(IMGQ_DEC, QUALITY) dequantizes the DCT
%   coefficients from IMQ_DEC where each row in IMQ_DEC corresponds to an
%   8x8 block. Uses the JPEG quantization matrix and zig zag scan for the 
%   given quality. The matrix of DCT coefficients for the frame is returned
%   in DCT_MAT_DEC.
%
%   M and N are the frame height and width respectively.

% get qt and zig zag pattern based on quality
[qt, zag] = init_jpeg(quality);

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

end
