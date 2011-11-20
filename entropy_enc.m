function [] = entropy_enc(frame_h, frame_w, frameq, bitstream_name, N_images, quality)
%ENTROPY_ENC Summary of this function goes here.
%   [] = ENTROPY_ENC(INPUT_ARGS) Detailed explanation goes here.
%
%   Bitstream will contain:
%       general info:
%           frame_h         uint16
%           frame_w         uint16
%           quality         uint8
%       for each frame:
%           min_index       int16
%           Ncoutns         uint16
%           counts          uint32*Ncounts
%           Nsymbols        uint32
%           Nbits           uint32
%           imgq_enc        ubit1*Nbits

% open bitstream for writing
fid = fopen(bitstream_name, 'w');

% write frame_h, frame_w and quality to the bitstream
fwrite(fid, [frame_h frame_w], 'uint16');
fwrite(fid, quality, 'uint8');

% encode each frame and add to bitstream
for k = 1:N_images

    % get imgq from frameq
    imgq = frameq(:,:,k);
    
    % get number of rows and columns in imgq
    [imgq_r, imgq_c] = size(imgq);

    % convert all elements in imgq to positive integers by adding min element
    % to all elements
    min_index = min(min(imgq));
    if (min_index < 0)
        imgq = imgq + abs(min_index) + 1; % pos integers don't include 0
    end

    % convert imgq to row vector by stringing rows together
    imgq = reshape(imgq, 1, imgq_r*imgq_c);

    % get histogram for imgq
    counts = hist(imgq, max(imgq));

    % replace 0s with 1s in counts
    ind = find(counts == 0);
    if ~(isempty(ind))
        counts(ind) = 1;
    end

    % write min index to bitstream
    fwrite(fid, min_index, 'int16');

    % write historgam and histogram size to bitstream
    fwrite(fid, length(counts), 'uint16');
    fwrite(fid, counts, 'uint32');

    % encode imgq using arithmetic encoding
    Nsymbols = length(imgq);
    imgq_enc = arithenco(imgq, counts);
    Nbits = length(imgq_enc);

    % write encoded bitstream
    fwrite(fid, Nsymbols, 'uint32');
    fwrite(fid, Nbits, 'uint32');
    fwrite(fid, imgq_enc, 'ubit1');

end

fclose(fid);

end
