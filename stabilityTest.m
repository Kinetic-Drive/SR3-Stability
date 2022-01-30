
clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
imtool close all;  % Close all imtool figures.
clear;  % Erase all existing variables.
workspace; 
fontSize = 22;


folder = fileparts(which('x40MphLineTest.mp4')); % Determine where demo folder is (works with all versions).
% Enter movie/video name.
% Comment out the other one.
movieFullFileName = fullfile(folder, '40 mph line test.mp4');
% movieFullFileName = fullfile(folder, 'traffic.avi');
% Check to see that it exists.
if ~exist(movieFullFileName, 'file')
	strErrorMessage = sprintf('File not found:\n%s\nYou can choose a new one, or cancel', movieFullFileName);
	response = questdlg(strErrorMessage, 'File not found', 'OK - choose a new movie.', 'Cancel', 'OK - choose a new movie.');
	if strcmpi(response, 'OK - choose a new movie.')
		[baseFileName, folderName, FilterIndex] = uigetfile('*.avi');
		if ~isequal(baseFileName, 0)
			movieFullFileName = fullfile(folderName, baseFileName);
		else
			return;
		end
	else
		return;
	end
end

try
	videoObject = VideoReader(movieFullFileName)
	% Determine how many frames there are.
	numberOfFrames = videoObject.NumberOfFrames;
	vidHeight = videoObject.Height;
	vidWidth = videoObject.Width;
	
	numberOfFramesWritten = 0;
	% Prepare a figure to show the images in the upper half of the screen.
	figure;
	% 	screenSize = get(0, 'ScreenSize');
	% Enlarge figure to full screen.
	set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
	
	% Ask user if they want to write the individual frames out to disk.
	promptMessage = sprintf('Do you want to save the individual frames out to individual disk files?');
	button = questdlg(promptMessage, 'Save individual frames?', 'Yes', 'No', 'Yes');
	if strcmp(button, 'Yes')
		writeToDisk = true;
		
		% Extract out the various parts of the filename.
		[folder, baseFileName, extentions] = fileparts(movieFullFileName);
		% Make up a special new output subfolder for all the separate
		% movie frames that we're going to extract and save to disk.
		
		folder = pwd;   % Make it a subfolder of the folder where this m-file lives.
		outputFolder = sprintf('%s/Movie Frames from %s', folder, baseFileName);
		% Create the folder if it doesn't exist already.
		if ~exist(outputFolder, 'dir')
			mkdir(outputFolder);
		end
	else
		writeToDisk = false;
	end
	
	% Loop through the movie, writing all frames out.
	% Each frame will be in a separate file with unique name.
    
	%calculate number of seconds in a single frame
	totalSeconds = numberOfFrames/30;
    sec = totalSeconds/numberOfFrames;
	for frame = 1 : numberOfFrames
		% Extract the frame from the movie structure.
		thisFrame = read(videoObject, frame);
		
		% Display it
		hImage = subplot(2, 2, 1);
		image(thisFrame);
		caption = sprintf('Frame %4d of %d.', frame, numberOfFrames);
		title(caption, 'FontSize', fontSize);
		drawnow; % Force it to refresh the window.
		
		% Write the image array to the output file, if requested.
		if writeToDisk
			% Construct an output image file name.
			outputBaseFileName = sprintf('Frame %4.4d.png', frame);
			outputFullFileName = fullfile(outputFolder, outputBaseFileName);
			
			% Stamp the name and frame number onto the image.
			% At this point it's just going into the overlay,
			% not actually getting written into the pixel values.
			text(5, 15, outputBaseFileName, 'FontSize', 20);
			
			% Extract the image with the text "burned into" it.
			frameWithText = getframe(gca);
			% frameWithText.cdata is the image with the text
			% actually written into the pixel values.
			% Write it out to disk.
			imwrite(frameWithText.cdata, outputFullFileName, 'png');
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		% make to gray scale
		grayImage = rgb2gray(thisFrame);
		%fps of video camera
        fps = 30;
		%create rectangular region for analysis study 
        zmask = zeros(1080, 1920);
        
        x = [813, 813, 1347, 1347, 813];
        y = [845, 855, 855, 845, 845];
        
        roi = uint8(poly2mask(x, y, 1080, 1920));
        
        newimg = grayImage.*roi;
       
        %find pixel of highest intensity (pixel of rope)

        [r, c] = find(newimg == max(newimg(:)));
        
        if max(newimg(:)) < 100
            c = 1080;
        end
        
        c = c(1);
        %calculate deviation from center pixel
        diff = c - 1080;
        d = (diff);

        %scale to distance in inches
        inch = d/23;
        inch = round(inch, 3);

        %seconds per frame
        
        s = frame * sec;
        %create plot 
        lineDev = [s, inch]
        x = s;
        y = inch;
        % Plot the line deviation
        hPlot = subplot(2, 2, 2);
        hold on;
        plot(x,y, 'b.')
        xlim([0, totalSeconds])
        ylim([-15, 15])
        hold on;
        grid on;

        % Put title back because plot() erases the existing title.
        title('Deviation vs Time', 'FontSize', fontSize);
        if frame == 1
            xlabel('Seconds (s)');
            ylabel('Deviation (inches)');
            % Get size data later for preallocation if we read
            % the movie back in from disk.
            [rows, columns, numberOfColorChannels] = size(thisFrame);
        end
		
		% Update user with the progress.  Display in the command window.
		if writeToDisk
			progressIndication = sprintf('Wrote frame %4d of %d.', frame, numberOfFrames);
		else
			progressIndication = sprintf('Processed frame %4d of %d.', frame, numberOfFrames);
		end
		disp(progressIndication);
		% Increment frame count (should eventually = numberOfFrames
		% unless an error happens).
		numberOfFramesWritten = numberOfFramesWritten + 1;
		
	end
	
	% Alert user that we're done.
	if writeToDisk
		finishedMessage = sprintf('Done!  It wrote %d frames to folder\n"%s"', numberOfFramesWritten, outputFolder);
	else
		finishedMessage = sprintf('Done!  It processed %d frames of\n"%s"', numberOfFramesWritten, movieFullFileName);
	end
	disp(finishedMessage); % Write to command window.
	uiwait(msgbox(finishedMessage)); % Also pop up a message box.
	
	% Exit if they didn't write any individual frames out to disk.
	if ~writeToDisk
		return;
	end
	
	% Ask user if they want to read the individual frames from the disk,
	% that they just wrote out, back into a movie and display it.
	promptMessage = sprintf('Do you want to recall the individual frames\nback from disk into a movie?\n(This will take several seconds.)');
	button = questdlg(promptMessage, 'Recall Movie?', 'Yes', 'No', 'Yes');
	if strcmp(button, 'No')
		return;
	end

	% Create a VideoWriter object to write the video out to a new, different file.
	writerObj = VideoWriter('NewStability.avi');
	open(writerObj);
	
	% Read the frames back in from disk, and convert them to a movie.
	% Preallocate recalledMovie, which will be an array of structures.
	% First get a cell array with all the frames.
	allTheFrames = cell(numberOfFrames,1);
	allTheFrames(:) = {zeros(vidHeight, vidWidth, 3, 'uint8')};
	% Next get a cell array with all the colormaps.
	allTheColorMaps = cell(numberOfFrames,1);
	allTheColorMaps(:) = {zeros(256, 3)};
	% Now combine these to make the array of structures.
	recalledMovie = struct('cdata', allTheFrames, 'colormap', allTheColorMaps)
	for frame = 1 : numberOfFrames
		% Construct an output image file name.
		outputBaseFileName = sprintf('Frame %4.4d.png', frame);
		outputFullFileName = fullfile(outputFolder, outputBaseFileName);
		% Read the image in from disk.
		thisFrame = imread(outputFullFileName);
		% Convert the image into a "movie frame" structure.
		recalledMovie(frame) = im2frame(thisFrame);
		% Write this frame out to a new video file.
		writeVideo(writerObj, thisFrame);
    end
	
catch ME
	% Some error happened if you get here.
	strErrorMessage = sprintf('Error extracting movie frames from:\n\n%s\n\nError: %s\n\n)', movieFullFileName, ME.message);
	uiwait(msgbox(strErrorMessage));
end

