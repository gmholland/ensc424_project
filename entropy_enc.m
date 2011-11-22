function [] = entropy_enc(frame_h, frame_w, frameq, mvxs, mvys, bitstream_name, N_images, quality)
%ENTROPY_ENC Summary of this function goes here.
%   [] = ENTROPY_ENC(INPUT_ARGS) Detailed explanation goes here.
%
%   Bitstream will contain:
%       general info:
%           frame_h         uint16
%           frame_w         uint16
%           quality         uint8
%       for each frame:
%         P frames:
%           mv_min_index    int16
%           Nmv_counts      uint16
%           mv_counts       uint32*Nmv_counts
%           Nbits_mv_enc    uint32
%           mv_enc          ubit1*Nbits_mv_enc
%           
%         P and I frames:
%           imgq_min_index  int16
%           Nimgq_counts    uint16
%           imgq_counts     uint32*Nimgq_counts
%           Nbits_imgq_enc  uint32
%           imgq_enc        ubit1*Nbits_imgq_enc

% open bitstream for writing
fid = fopen(bitstream_name, 'w');

% write frame_h, frame_w and quality to the bitstream
fwrite(fid, [frame_h frame_w], 'uint16');
fwrite(fid, quality, 'uint8');

% encode each frame and add to bitstream
for k = 1:N_images

    % encode the motion vectors for P frames
    if (k ~= 1)
        % get mvx and mvy from motion vector arrays and convert to
        % row vectors 
        Nmvs = frame_h*frame_w/64; % number of motion vectors for each axis
        mvx = reshape(mvxs(:,:,k-1), 1, Nmvs);
        mvy = reshape(mvys(:,:,k-1), 1, Nmvs);

        % perform differential coding on the motion vectors
        mvxdiff = zeros(1,Nmvs-1);
        mvydiff = zeros(1,Nmvs-1);
        for i = 2:Nmvs
            mvxdiff(i-1) = mvx(i) - mvx(i-1);
            mvydiff(i-1) = mvy(i) - mvy(i-1);
        end
        mvx(2:end) = mvxdiff;
        mvy(2:end) = mvydiff;
        clear mvxdiff mvydiff;

        % concatenate motion vector vectors
        mv = [mvx, mvy];
        clear mvx mvy;

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
    imgq = frameq(:,:,k);
    
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
