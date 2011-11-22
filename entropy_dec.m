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

    fprintf(' .');

    % read in info for each frame from bitstream to aid decoding
    if (k ~= 1)
        % motion vectors
        mv_min_index = fread(fid, 1, 'int16=>double');
        Nmv_counts = fread(fid, 1, 'uint16=>double');
        mv_counts = fread(fid, Nmv_counts, 'uint32=>double');
        Nbits_mv_enc = fread(fid, 1, 'uint32=>double');
        mv_enc = fread(fid, Nbits_mv_enc, 'ubit1=>double');

        % decode mv_enc using arithmetic decoder
        Nsymbols = 2*frame_h*frame_w/64; 
        mv_dec = arithdeco(mv_enc, mv_counts, Nsymbols);

        % convert elements in imgq_dec back to positive and negative numbers 
        % using mv_min_index
        if (mv_min_index < 0)
            mv_dec = mv_dec - (abs(mv_min_index) + 1);
        end

        % split motion vectors into their own vectors
        Nmvs = frame_h*frame_w/64; % number of motion vectors 
        mvx_dec = mv_dec(1:Nmvs);
        mvy_dec = mv_dec(Nmvs+1:end);

        % perform inverse differential coding to get motion vectors back
        for i = 2:Nmvs
            mvx_dec(i) = mvx_dec(i) + mvx_dec(i-1);
            mvy_dec(i) = mvy_dec(i) + mvy_dec(i-1);
        end

        % reshape motion vectors to matrices
        mvx_dec = reshape(mvx_dec, frame_h/8, frame_w/8);
        mvy_dec = reshape(mvy_dec, frame_h/8, frame_w/8);
        
        % store in appropriate place in mvxs and mvys for returning
        mvxs(:,:,k-1) = mvx_dec;
        mvys(:,:,k-1) = mvy_dec;

    end

    imgq_min_index = fread(fid, 1, 'int16=>double');
    Nimgq_counts = fread(fid, 1, 'uint16=>double');
    imgq_counts = fread(fid, Nimgq_counts, 'uint32=>double');
    Nbits = fread(fid, 1, 'uint32=>double');
    imgq_enc = fread(fid, Nbits, 'ubit1=>double');

    % decode imgq_enc using arithmetic decoder
    Nsymbols = frame_h*frame_w; 
    imgq_dec = arithdeco(imgq_enc, imgq_counts, Nsymbols);
    
    % convert imgq_dec to matrix
    imgq_dec = reshape(imgq_dec, frame_h*frame_w/64, 64);

    % convert elements in imgq_dec back to positive and negative numbers using
    % imgq_min_index
    if (imgq_min_index < 0)
        imgq_dec = imgq_dec - (abs(imgq_min_index) + 1);
    end

    % write imgq to appropriate place in frameq_dec
    frameq_dec(:,:,k) = imgq_dec;
end

fclose(fid);

end
