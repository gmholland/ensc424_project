function [frame_h, frame_w, quality, frame_infos, frameq_dec, mvxs, mvys] = entropy_dec(bitstream_name, N_images)
%ENTROPY_DEC Summary of this function goes here.
%   [] = ENTROPY_DEC(INPUT_ARGS) Detailed explanation goes here.
%
%   See also entropy_enc

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

% initialize frame_infos based on N_images
for k = 1:N_images
    frame_infos(k) = struct('num', 0, 'type', 0, 'fwd_ref', 0, ...
        'back_ref', 0, 'wf', 0, 'wb', 0);
end

% initialize mvxs and mvys based on frame_h and frame_w
mvxs = zeros(frame_h/8, frame_w/8, N_images);
mvys = zeros(frame_h/8, frame_w/8, N_images);

% get zig zag indexing pattern for motion vectors
zag = init_zag(frame_h/8, frame_w/8, 'horizontal');

for k = 1:N_images

    fprintf(' .');

    % read in frame_info from bitstream
    frame_infos(k).num = fread(fid, 1, 'uint8=>double');
    frame_infos(k).type = fread(fid, 1, 'uint8=>char');

    % get frame_info to work on
    frame_info = frame_infos(k);

    % read in info for each frame from bitstream to aid decoding
    % P frames
    if (strcmp(frame_info.type, 'P'))
        % read in fwd_ref
        frame_info.fwd_ref = fread(fid, 1, 'uint8=>double');
        % write back to frame_infos for return values
        frame_infos(k) = frame_info;

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

        % reshape motion vectors to matrices using zig zag pattern
        mvx_dec = mvx_dec(zag);
        mvy_dec = mvy_dec(zag);
        
        % store in appropriate place in mvxs and mvys for returning
        mvxs(:,:,frame_info.num) = mvx_dec;
        mvys(:,:,frame_info.num) = mvy_dec;

    end

    % do these steps for all frame types
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
    frameq_dec(:,:,frame_info.num) = imgq_dec;
end

fclose(fid);

end
