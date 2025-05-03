%{ 
  DIY 3D Scanner Post-Processing Code (DIY 3D Scanner - Super Make Something Episode 8)
  by: Alex - Super Make Something
  date: January 2nd, 2016
  license: Creative Commons - Attribution - Non-Commercial.  
  More information available at: http://creativecommons.org/licenses/by-nc/3.0/
%}

clear all;
clc;

%% Processing variables
maxDistance = 15;     % Upper limit -- raw scan value only scanning "air"
minDistance = 0;      % Lower limit -- raw scan value error: reporting negative reading

midThreshUpper = 0.5; % Offset radius threshold around 0
midThreshLower = -midThreshUpper; % Offset radius threshold around 0

windowSize = 3;  % Window size for average filter to clean up mesh
interpRes = 1;   % Interpolation resolution, i.e. keep every interRes-th row

% Set centerDistance high enough so that the offset values are positive.
centerDistance = 15.0
.5 % [cm] - Adjusted: Distance from scanner to center of turntable
zDelta = 0.1;

% Load raw data (replace filename as needed)
rawData = load('SCN00.TXT'); % Load text file from SD Card
rawData(rawData < 0) = 0;       % Remove erroneous scans from raw data

% Find indices of the delimiter (9999) that indicate end of a z-height scan
indeces = find(rawData == 9999);

%% Segment data into layers using a cell array
numLayers = length(indeces);
rCell = cell(numLayers, 1);
for i = 1:numLayers
    if i == 1
        rCell{i} = rawData(1:indeces(1));
    else
        rCell{i} = rawData(indeces(i-1)+1:indeces(i));
    end
    % Remove trailing delimiter if present
    if ~isempty(rCell{i}) && rCell{i}(end) == 9999
         rCell{i}(end) = [];
    end
end

% Convert the cell array into a rectangular matrix by padding rows with NaN
maxLength = max(cellfun(@length, rCell));
r = NaN(numLayers, maxLength);
for i = 1:numLayers
    len = length(rCell{i});
    r(i, 1:len) = rCell{i};
end

%% Post-process the scan matrix r

% Offset scan so that distance is with respect to turntable center
r = centerDistance - r;

% Remove scan values outside valid range
r(r > maxDistance) = NaN;
r(r < minDistance) = NaN;

% Remove scan values around 0 (set to NaN)
midThreshIdx = (r > midThreshLower) & (r < midThreshUpper);
r(midThreshIdx) = NaN;

% Create theta matrix (each column corresponds to a specific orientation)
theta = 360:-360/size(r,2):0;
theta(end) = [];
theta = repmat(theta, [size(r,1) 1]);
theta = theta * pi / 180; % Convert degrees to radians

% Create z-height array where each row corresponds to one z-height
z = 0:zDelta:(size(r,1) * zDelta);
z(end) = [];
z = z';
z = repmat(z, [1, size(r,2)]);

% Convert polar to Cartesian coordinates
[x, y, z] = pol2cart(theta, r, z);

%% Replace NaN values in x and y with the nearest valid neighbor at the same height

% Remove entire rows if all x-values are NaN
for i = 1:size(x,1)
   if all(isnan(x(i,:)))
      x(i:end, :) = [];
      y(i:end, :) = [];
      z(i:end, :) = [];
      break;
   end
end

% For each row, replace NaNs with the latest valid (non-NaN) value
for i = 1:size(x,1)
   latestX = NaN;
   latestY = NaN;
   for j = 1:size(x,2)
       if ~isnan(x(i,j))
           latestX = x(i,j);
           latestY = y(i,j);
       elseif ~isnan(latestX)
           x(i,j) = latestX;
           y(i,j) = latestY;
       end
   end
end

%% Resample array based on desired mesh resolution
interpIdx = 1:interpRes:size(x,1);
xInterp = x(interpIdx, :);
yInterp = y(interpIdx, :);
zInterp = z(interpIdx, :);

%% Smooth data to reduce noise using an average filter
h = fspecial('average', windowSize); % Define average filter

% Pad arrays to properly filter the edges
xInterp = padarray(xInterp, [0, windowSize], 'symmetric');
yInterp = padarray(yInterp, [0, windowSize], 'symmetric');

xInterp = filter2(h, xInterp);
yInterp = filter2(h, yInterp);

% Remove padding
xInterp = xInterp(:, windowSize:end-windowSize-1);
yInterp = yInterp(:, windowSize:end-windowSize-1);

% Ensure wrapping by duplicating the first column at the end if more than one column exists.
if size(xInterp,2) > 1
    xInterp(:, end+1) = xInterp(:, 1);
    yInterp(:, end+1) = yInterp(:, 1);
    zInterp(:, end+1) = zInterp(:, 1);
end

%% Add a top to close the shape
if isempty(xInterp)
    error('xInterp is empty. No valid data remains after processing. Please check your raw scan data.');
end

if size(xInterp, 1) < 2
    error('Not enough data rows in xInterp to compute a top. Please check your data segmentation.');
end

xTop = mean(xInterp(end, :));
yTop = mean(yInterp(end, :));
xInterp(end+1, :) = xTop;
yInterp(end+1, :) = yTop;
zInterp(end+1, :) = zInterp(end,1) - (zInterp(end,1) - zInterp(end-1,1));

%% Plot the point cloud to verify processing
figure;
plot3(xInterp, yInterp, zInterp, '.b');
title('Processed 3D Scan Data');
xlabel('X');
ylabel('Y');
zlabel('Z');

%% Export as STL file
surf2stl('SCN000.STL', xInterp, yInterp, zInterp);
