function [MSEs, PSNRs, bitrates] = run_codec(name, dec_name, N_images)
%RUN_CODEC Run the project codec at various quaility levels
%   [MSEs, PSNRs, bitrates] = RUN_CODEC(NAME, DEC_NAME, N_IMAGES)

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
for quality = [50]

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
    bench_PSNRs = [23.5 28 31 40.5];
    bench_bitrates = [0.19 0.42 0.88 3];
elseif strcmp(name, 'art')
    bench_PSNRs = [23.7 30 32.6 35.1 43.5];
    bench_bitrates = [0.12 0.41 0.64 0.95 2.4];
end
plot(bench_bitrates, bench_PSNRs, 'r');
hold off;

fprintf('done\n');

end
