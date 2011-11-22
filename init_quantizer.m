function [qt, zag] = init_quantizer(quant_type, quality)
% INIT_JPEG Initialize quantization table and zig-zag scan for image coding.
%    [QT, ZAG] = INIT_QUANTIZER(QUANT_TYPE, QUALITY) 
%    Returns the a row vector QT which is the quantization step sizes for the 
%    DCT coefficients of an 8x8 block. 
%    
%    QUANT_TYPE specifies the quantizer type and must be one of 'uniform' or
%    'jpeg', where uniform returns a uniform quantizer while 'jpeg' returns 
%    a JPEG-like quantizer.
%
%    In both cases the elements of QT are scaled by QUALITY which should be 
%    in the range 1 to 100
%    
%    ZAG is an 8x8 matrix with the zig zag pattern of the DCT coefficients.

% quantization step sizes for DCT coefficients of an 8x8 block
% jpeg quantizer
if (strcmp(quant_type, 'jpeg'))
    qt = [16   11   10   16   24   40   51   61; ...
        12   12   14   19   26   58   60   55; ...
        14   13   16   24   40   57   69   56; ...
        14   17   22   29   51   87   80   62; ...
        18   22   37   56   68  109  103   77; ...
        24   35   59   64   81  104  113   92; ...
        49   64   78   87  103  121  120  101; ...
        72   92   95   98  112  100  103   99];
% uniform quantizer
elseif strcmp(quant_type, 'uniform')
    qt = zeros(8,8) + 16;
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


% do a zig-zag scan of qt
x = zeros(1,64);  
x(zag) = qt;
qt = x;
clear x
      
if (quality <= 0)
    quality = 1;
elseif (quality > 100)
    quality = 100;
end
if (quality < 50)
    quality = 5000/quality;
else
    quality = 200 - 2*quality;
end

% Scale the quantization table according to quality parameter. If
% quality=50, qualtization table stays the same.
for i = 1:64
    temp = (qt(i)*quality + 50)/100;
    if (temp <= 1)
        temp = 1;
    elseif (temp > 255)
        temp = 255;
    end
    qt(i) = floor(temp);
end

