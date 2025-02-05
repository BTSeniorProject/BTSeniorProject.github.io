% Multilateration Using a Moving Point
%
% This code will use four sensors in different corners of a square shape
% in order to find the the location of a BT device.
%
% ------> The X's will represent sensors (Rasp. Pi) and the O will
%         represent the BT device emitting MAC/RSSI signals. Each
%         device will we be 5 meters apart. Using Pythageraon theorm,
%         it is obvious that the distance from the BT device to each
%         sensor will be 7.071 meters apart. *(Actually 3.905 meters)*
%
%                   |     X         X     |
%                   |                     |
%                   |          O          |
%                   |                     |
%                   |     X         X     |
%
%% Initializing Variables
%

close all; % Close all figures and clear workspace
clear;
sensorFiles = {'BTSensor1_Moving_Data.txt', 'BTSensor2_Moving_Data.txt', 'BTSensor3_Moving_Data.txt', 'BTSensor4_Moving_Data.txt'};


%%
% Sensor locations (in meters) [x, y]
sensorLocations = [0, 0;       % Sensor 1 at (0, 0)
                   5, 0;      % Sensor 2 at (5, 0)
                   0, 5;      % Sensor 3 at (0, 5)
                   5, 5];    % Sensor 4 at (5, 5)

% Define the update interval
updateInterval = 1; % 0.25 seconds

% Initialize figure for plotting
% figure;
% hold on;

% Infinite loop for real-time monitoring
%while true
    % Combine data from all sensor files
    combinedData = table();
    for i = 1:length(sensorFiles)
        % Define import options for the current file
        opts = detectImportOptions(sensorFiles{i}, 'Delimiter', ',');
        opts.VariableNames = {'Timestamp', 'ID', 'Name', 'Address', 'RSSI', 'Distance'};
        opts = setvartype(opts, {'Timestamp', 'ID', 'Name', 'Address'}, 'string'); 
        opts = setvartype(opts, {'RSSI', 'Distance'}, 'double'); 
        
        % Read the current file into a table
        data = readtable(sensorFiles{i}, opts);

        % Append to combinedData
        combinedData = [combinedData; data];
    end


    % Convert Timestamp to datetime for easier processing
    %combinedData.Timestamp = datetime(combinedData.Timestamp, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS');
    combinedData.Timestamp = datetime(combinedData.Timestamp, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS');
    combinedData.Timestamp.Format = 'yyyy-MM-dd HH:mm:ss.SSS';

    % Get the latest timestamp data
    for j = 1:length(combinedData.Timestamp)/4
    latestTime = combinedData.Timestamp(j);

    % Filter the latest data (last 0.25 seconds)
    %recentData = combinedData(combinedData.Timestamp >= latestTime - seconds(updateInterval), :);
    recentData = combinedData(combinedData.Timestamp == latestTime, :); % Sketchy way to do this lol

    % Clear the previous plot
    clf;

    % Plot the data and perform multilateration
    if ~isempty(recentData)
        % Extract distances for multilateration
        distances = recentData.Distance(1:min(4, height(recentData))); % Use up to 4 sensors

        % Perform multilateration if we have at least 4 distances
        if length(distances) >= 4
            % Call the multilateration function
            estimatedPosition = multilaterate(sensorLocations, distances);

            % Plot sensor locations
            plot(sensorLocations(:, 1), sensorLocations(:, 2), 'ro', 'MarkerSize', 10, 'DisplayName', 'Sensors');
            axis([0 5 0 5])
            hold on 
            % Plot the estimated position
            plot(estimatedPosition(1), estimatedPosition(2), 'bx', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Estimated Position');
            
            % Add labels and legend
            xlabel('X Position (m)');
            ylabel('Y Position (m)');
            title(sprintf('Estimated Position at Time: %s', datestr(latestTime)));
            legend('show');
        end
    end
pause(updateInterval);

    end

    % Pause for the update interval
%end
