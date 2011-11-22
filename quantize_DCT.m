function imgq = quantize_DCT(dct_frame, quant_type, quality)
%QUANTIZE_DCT Quantize DCT coefficients
%   IMGQ = QUANTIZE_DCT(DCT_FRAME, QUANT_TYPE, QUALITY) quantizes the image 
%   frame DCT_FRAME using the quantization matrix and zig-zag pattern. 
%   
%   There are two options for QUANT_TYPE, 'jpeg' or 'uniform'. 'jpeg' uses
%   jpeg quantizer for the given QUALITY while 'uniform' uses a uniform 
%   quantizer.
%
%   The quantized DCT coefficients for each block appear in each row of 
%   IMGQ. IMGQ is therefore a M*N/64 by 64 matrix where the dimensions of 
%   DCT_FRAME are M by N.

[M, N] = size(dct_frame);

% get quantization and zig-zag matrices
if strcmp(quant_type, 'jpeg')
    [qt, zag] = init_jpeg(quality);
elseif strcmp(quant_type, 'uniform')
    qt = zeros(1,64) + 16;
    % Scale the quantization table according to quality parameter. If
    % quality=50, qualtization table stays the same.
    for i = 1:64
        temp = (qt(i)*quality + 50)/100;
        if (temp <= 0)
            temp = 1;
        elseif (temp > 255)
            temp = 255;
        end
        qt(i) = floor(temp);
    end

    % zig-zag scan of the coefficients in 8x8 block
    zag = [0   1   5   6  14  15  27  28; ...
           2   4   7  13  16  26  29  42; ...
           3   8  12  17  25  30  41  43; ...
           9  11  18  24  31  40  44  53; ...
           10  19  23  32  39  45  52  54; ...
           20  22  33  38  46  51  55  60; ...
           21  34  37  47  50  56  59  61; ...
           35  36  48  49  57  58  62  63] + 1;
end

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
