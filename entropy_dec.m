function [frame_h, frame_w, quality, frameq_dec, mvxs, mvys] = entropy_dec(bitstream_name, N_images)
%ENTROPY_DEC Summary of this function goes here.
%   [] = ENTROPY_DEC(INPUT_ARGS) Detailed explanation goes here.

% open bitstream for reading
fid = fopen(bitstream_name, 'r');

% read in header info from bitstream
res = fread(fid, 2, 'uint16=>double').';
frame_h = res(1);
frame_w = res(2);
clear res;
quality = fread(fid, 1, 'uint8=>double');

% initialize frameq based on frame_h, frame_w 
frameq_dec = zeros(frame_h*frame_w/64, 64, N_images);

% initialize mvxs and mvys based on frame_h and frame_w
mvxs = zeros(frame_h/8, frame_w/8, N_images-1);
mvys = zeros(frame_h/8, frame_w/8, N_images-1);

for k = 1:N_images

    % read in info for each frame from bitstream to aid decoding
    if (k ~= 1)
        % motion vectors
        mvx = fread(fid, frame_h*frame_w/64, 'int8=>double');
        mvy = fread(fid, frame_h*frame_w/64, 'int8=>double');
        mvxs(:,:,k-1) = reshape(mvx, frame_h/8, frame_w/8);
        mvys(:,:,k-1) = reshape(mvy, frame_h/8, frame_w/8);
        clear mvx mvy;
    end

    min_index = fread(fid, 1, 'int16=>double');
    Ncounts = fread(fid, 1, 'uint16=>double');
    counts = fread(fid, Ncounts, 'uint32=>double');
    Nbits = fread(fid, 1, 'uint32=>double');
    imgq_enc = fread(fid, Nbits, 'ubit1=>double');

    % decode imgq_enc using arithmetic decoder
    Nsymbols = frame_h*frame_w; 
    imgq_dec = arithdeco(imgq_enc, counts, Nsymbols);
    
    % convert imgq_dec to matrix
    imgq_dec = reshape(imgq_dec, frame_h*frame_w/64, 64);

    % convert elements in imgq_dec back to positive and negative numbers using
    % min_index
    if (min_index < 0)
        imgq_dec = imgq_dec - (abs(min_index) + 1);
    end

    % write imgq to appropriate place in frameq_dec
    frameq_dec(:,:,k) = imgq_dec;
end

fclose(fid);

end
