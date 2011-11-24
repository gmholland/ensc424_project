function [] = entropy_enc(frame_h, frame_w, frame_infos, frameq, ...
                          fwd_mvxs, fwd_mvys, back_mvxs, back_mvys, ...
                          bitstream_name, N_images, quality)
%ENTROPY_ENC Summary of this function goes here.
%   [] = ENTROPY_ENC(INPUT_ARGS) Detailed explanation goes here.
%
%   Bitstream will contain (in this order):
%       general info:
%           frame_h         uint16
%           frame_w         uint16
%           quality         uint8
%
%       for each frame:
%         I, P and B frames:
%           frame_num       uint8
%           frame_type      uint8
%         
%         B frames:
%           fwd_ref         uint8
%           back_ref        uint8
%           wb              single
%           mv_min_index    int16
%           Nmv_counts      uint16
%           mv_counts       uint32*Nmv_counts
%           Nbits_mv_enc    uint32
%           mv_enc          ubit1*Nbits_mv_enc
%
%         P frames:
%           fwd_ref         uint8
%           mv_min_index    int16
%           Nmv_counts      uint16
%           mv_counts       uint32*Nmv_counts
%           Nbits_mv_enc    uint32
%           mv_enc          ubit1*Nbits_mv_enc
%           
%         I, P and B frames:
%           imgq_min_index  int16
%           Nimgq_counts    uint16
%           imgq_counts     uint32*Nimgq_counts
%           Nbits_imgq_enc  uint32
%           imgq_enc        ubit1*Nbits_imgq_enc
%
%   See also entropy_dec

% open bitstream for writing
fid = fopen(bitstream_name, 'w');

% write frame_h, frame_w and quality to the bitstream
fwrite(fid, [frame_h frame_w], 'uint16');
fwrite(fid, quality, 'uint8');

% initialize row vector form of motion vectors
fwd_mvx = zeros(1, frame_h*frame_w/64);
fwd_mvy = zeros(1, frame_h*frame_w/64);
back_mvx = zeros(1, frame_h*frame_w/64);
back_mvy = zeros(1, frame_h*frame_w/64);

% get zig zag indexing pattern for motion vectors
zag = init_zag(frame_h/8, frame_w/8, 'horizontal');

% encode each frame and add to bitstream
for k = 1:N_images

    fprintf(' .');

    % get current frame information
    frame_info = frame_infos(1,k); % frame_infos is a 1xN_images struct array

    % write frame number and type to bitstream
    fwrite(fid, frame_info.num, 'uint8');
    fwrite(fid, frame_info.type, 'uint8');

    % encode the motion vectors for B frames
    if (strcmp(frame_info.type, 'B'))
        % write fwd reference number to bitstream
        fwrite(fid, frame_info.fwd_ref, 'uint8');

        % write back reference number to bitstream
        fwrite(fid, frame_info.back_ref, 'uint8');

        % write wb (back weight) to bitstream
        % note: wf = 1 - wb so it need not be encoded
        fwrite(fid, frame_info.wb, 'single'); % must be floating point

        % get fwd_mvx and fwd_mvy from fwd motion vector arrays and convert to
        % row vectors using zig zag pattern. do the same for back_mvx and back_mvy
        Nmvs = frame_h*frame_w/64; % number of motion vectors for each axis
        fwd_mvx(zag) = fwd_mvxs(:,:,frame_info.num);
        fwd_mvy(zag) = fwd_mvys(:,:,frame_info.num);
        back_mvx(zag) = back_mvxs(:,:,frame_info.num);
        back_mvy(zag) = back_mvys(:,:,frame_info.num);

        % perform differential coding on the forward and backward motion vectors
        fwd_mvxdiff = zeros(1,Nmvs-1);
        fwd_mvydiff = zeros(1,Nmvs-1);
        back_mvxdiff = zeros(1,Nmvs-1);
        back_mvydiff = zeros(1,Nmvs-1);
        for i = 2:Nmvs
            fwd_mvxdiff(i-1) = fwd_mvx(i) - fwd_mvx(i-1);
            fwd_mvydiff(i-1) = fwd_mvy(i) - fwd_mvy(i-1);
            back_mvxdiff(i-1) = back_mvx(i) - back_mvx(i-1);
            back_mvydiff(i-1) = back_mvy(i) - back_mvy(i-1);
        end
        fwd_mvx(2:end) = fwd_mvxdiff;
        fwd_mvy(2:end) = fwd_mvydiff;
        back_mvx(2:end) = back_mvxdiff;
        back_mvy(2:end) = back_mvydiff;
        clear fwd_mvxdiff fwd_mvydiff back_mvxdiff back_mvydiff;

        % concatenate forward and backward motion vector vectors
        mv = [fwd_mvx, fwd_mvy, back_mvx, back_mvy];

        % convert mvs to positive numbers by adding the min element
        mv_min_index = min(min(mv));
        if (mv_min_index < 0)
            mv = mv + abs(mv_min_index) + 1; % pos integers don't include 0
        end
        
        % get histogram for mv
        mv_counts = hist(mv, max(mv));

        % replace 0s with 1s in mv_counts
        ind = find(mv_counts == 0);
        if ~(isempty(ind))
            mv_counts(ind) = 1;
        end

        % write min index to bitstream
        fwrite(fid, mv_min_index, 'int16');

        % write histogram and histogram size to bitstream
        fwrite(fid, length(mv_counts), 'uint16');
        fwrite(fid, mv_counts, 'uint32');

        % encode mv using arithmetic encoding
        mv_enc = arithenco(mv, mv_counts);
        Nbits_mv_enc = length(mv_enc);

        % write encoded mvs to bitstream
        fwrite(fid, Nbits_mv_enc, 'uint32');
        fwrite(fid, mv_enc, 'ubit1');

    % encode the motion vectors for P frames
    elseif (strcmp(frame_info.type, 'P'))
        % write fwd reference number to bitstream
        fwrite(fid, frame_info.fwd_ref, 'uint8');

        % get mvx and mvy from motion vector arrays and convert to
        % row vectors using zig zag pattern
        Nmvs = frame_h*frame_w/64; % number of motion vectors for each axis
        fwd_mvx(zag) = fwd_mvxs(:,:,frame_info.num);
        fwd_mvy(zag) = fwd_mvys(:,:,frame_info.num);

        % perform differential coding on the motion vectors
        fwd_mvxdiff = zeros(1,Nmvs-1);
        fwd_mvydiff = zeros(1,Nmvs-1);
        for i = 2:Nmvs
            fwd_mvxdiff(i-1) = fwd_mvx(i) - fwd_mvx(i-1);
            fwd_mvydiff(i-1) = fwd_mvy(i) - fwd_mvy(i-1);
        end
        fwd_mvx(2:end) = fwd_mvxdiff;
        fwd_mvy(2:end) = fwd_mvydiff;
        clear fwd_mvxdiff fwd_mvydiff;

        % concatenate motion vector vectors
        mv = [fwd_mvx, fwd_mvy];
        clear fwd_mvx fwd_mvy;

        % convert mvs to positive numbers by adding the min element
        mv_min_index = min(min(mv));
        if (mv_min_index < 0)
            mv = mv + abs(mv_min_index) + 1; % pos integers don't include 0
        end
        
        % get histogram for mv
        mv_counts = hist(mv, max(mv));

        % replace 0s with 1s in mv_counts
        ind = find(mv_counts == 0);
        if ~(isempty(ind))
            mv_counts(ind) = 1;
        end

        % write min index to bitstream
        fwrite(fid, mv_min_index, 'int16');

        % write histogram and histogram size to bitstream
        fwrite(fid, length(mv_counts), 'uint16');
        fwrite(fid, mv_counts, 'uint32');

        % encode mv using arithmetic encoding
        mv_enc = arithenco(mv, mv_counts);
        Nbits_mv_enc = length(mv_enc);

        % write encoded mvs to bitstream
        fwrite(fid, Nbits_mv_enc, 'uint32');
        fwrite(fid, mv_enc, 'ubit1');

    end

    % get imgq from frameq
    imgq = frameq(:,:,frame_info.num);
    
    % get number of rows and columns in imgq
    [imgq_r, imgq_c] = size(imgq);

    % convert all elements in imgq to positive integers by adding min element
    % to all elements
    imgq_min_index = min(min(imgq));
    if (imgq_min_index < 0)
        imgq = imgq + abs(imgq_min_index) + 1; % pos integers don't include 0
    end

    % convert imgq to row vector by stringing rows together
    imgq = reshape(imgq, 1, imgq_r*imgq_c);

    % get histogram for imgq
    imgq_counts = hist(imgq, max(imgq));

    % replace 0s with 1s in imgq_counts
    ind = find(imgq_counts == 0);
    if ~(isempty(ind))
        imgq_counts(ind) = 1;
    end

    % write min index to bitstream
    fwrite(fid, imgq_min_index, 'int16');

    % write histogram and histogram size to bitstream
    fwrite(fid, length(imgq_counts), 'uint16');
    fwrite(fid, imgq_counts, 'uint32');

    % encode imgq using arithmetic encoding
    imgq_enc = arithenco(imgq, imgq_counts);
    Nbits_imgq_enc = length(imgq_enc);

    % write encoded image to bitstream
    fwrite(fid, Nbits_imgq_enc, 'uint32');
    fwrite(fid, imgq_enc, 'ubit1');

end

fclose(fid);

end
