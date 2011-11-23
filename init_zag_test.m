for frame_w = 2:8
    for frame_h = 2:8
        zag = init_zag(frame_h, frame_w, 'diagonal')
    end
end

for frame_w = 2:8
    for frame_h = 2:8
        zag = init_zag(frame_h, frame_w, 'horizontal')
    end
end

for frame_w = 2:8
    for frame_h = 2:8
        zag = init_zag(frame_h, frame_w, 'vertical')
    end
end

