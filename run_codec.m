function [MSEs, PSNRs, bitrates] = run_codec(name, dec_name, N_images, qualities)
%RUN_CODEC Run the project codec at various quaility levels
%   [MSEs, PSNRs, BITRATES] = RUN_CODEC(NAME, DEC_NAME, N_IMAGES, QUALITIES) 
%   Runs the project codec on the image set with common prefix of NAME that 
%   contains N_IMAGES different images. DEC_NAME specifies the common prefix 
%   to use for naming the decoded images. The encoder and decoder are run
%   once for each quality value specified in the row vector QUALITIES.
%
%   This function also computes MSE, PSNR and bitrates in bits in bits per
%   pixel for each quality value in QUALITIES. These stats are returned in
%   MSEs, PSNRs and BITRATES respectively. Additionally these results are 
%   saved to a MAT file with filename NAME.MAT.
%
%   The rate-distortion curve for the codec is also plotted. Additionally,
%   if NAME is one of 'aloe' or 'art', the benchmark rate-distortion curves
%   for the project are plotted in red on the same plot.
%   
%   See also im_encode im_decode

bitstream_name = strcat(name, '.bit');

% initialize stats
MSEs = [];
PSNRs = [];
bitrates = [];

% read in first file from set to get resolution
A = imread(strcat(name, '0.pgm'));
[im_h im_w] = size(A);
clear A;

% initialize 3D arrays for original and decoded images
originals = zeros(im_h, im_w, N_images);
decoded = zeros(im_h, im_w, N_images);

% read in the original images
for k = 1:N_images
    originals(:,:,k) = imread(strcat(name, num2str(k-1), '.pgm'));
end

% run codec at various quality levels
for quality = qualities

    fprintf('running at quality %d ...\n', quality);
    
    % time the operation at each quality level
    tic;

    % encode images
    fprintf('\t running encoder...');
    im_encode(name, bitstream_name, N_images, quality);
    fprintf('done\n');

    fprintf('\t running decoder...');
    % decode images
    im_decode(bitstream_name, dec_name, N_images);
    fprintf('done\n');

    % calculate MSE, PSNR and bitrate
    % read in the decoded files
    for k = 1:N_images
        decoded(:,:,k) = imread(strcat(dec_name, num2str(k-1), '.pgm'));
    end

    % calculate MSE and PSNR
    MSE = mean(mean(mean((originals - decoded).^2)));
    PSNR = 10*log10(255^2/MSE);

    % get filesize of bitstream
    bitstream_info = dir(bitstream_name);
    filesize = bitstream_info.bytes; % filesize in bytes
    Npixels = im_h*im_w*N_images;
    bitrate = filesize*8/Npixels; % convert bytes to bits
    
    % store stats
    MSEs = [MSEs MSE];
    PSNRs = [PSNRs PSNR];
    bitrates = [bitrates bitrate];

    % print stats
    fprintf('\n\t statistics for quality %d:\n', quality);
    fprintf('\t MSE      PSNR      bitrate\n');
    fprintf('\t %8.4f %8.4f %8.4f\n\n', MSE, PSNR, bitrate);

    fprintf('\t removing temporary files...');
    % delete temporary files
    delete(bitstream_name);
    for k = 1:N_images
        delete(strcat(dec_name, num2str(k-1), '.pgm'));
    end
    fprintf('done\n');
    toc;
    
end

% plot rate distortion graph
fprintf('plotting rate distortion curves...');

figure;
hold on;
grid on;
plot(bitrates, PSNRs, 'bo-');
title(name);
ylabel('PSNR (dB)');
xlabel('Bit rate (bpp)');
set(gcf, 'NumberTitle', 'off');
set(gcf, 'Name', name);

% plot benchmark
if strcmp(name, 'aloe')

    bench_bitrates = [0.0862, 0.4450, 0.7593, 0.9937, 1.1820, 1.3319, ...
                        1.5260, 1.7757, 2.1720, 2.9784];
    bench_PSNRs = [23.2726, 28.4010, 30.6222, 31.8449, 32.7096, 33.3621, ...
                        34.1092, 35.1255, 36.7873, 40.3812];

elseif strcmp(name, 'art')

    bench_bitrates = [0.1115, 0.4071, 0.6388, 0.8118, 0.9540, 1.0701, ...
                        1.2230, 1.4196, 1.7415, 2.4058];
    bench_PSNRs = [23.6614, 30.0541, 32.6378, 34.0639, 35.0819, 35.8541, ...
                        36.7400, 37.8486, 39.5591, 42.8749];

end
plot(bench_bitrates, bench_PSNRs, 'r');
hold off;

% store stats to MAT file
save(name, 'MSEs', 'PSNRs', 'bitrates');

fprintf('done\n');

end
