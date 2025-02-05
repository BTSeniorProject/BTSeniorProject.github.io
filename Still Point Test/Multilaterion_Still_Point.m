% Multilateration Using a Still Point
%
% This code will use four sensors in different corners of a square shape
% in order to find the the location of a BT device.
%
% ------> The X's will represent sensors (Rasp. Pi) and the O will
%         represent the BT device emitting MAC/RSSI signals. The Sensors
%         will be placed at (0,0), (0,5), (5,0), and (5,5). Using Pythageraon theorm,
%         it is obvious that the distance from the BT device to each
%         sensor will be 3.535 meters apart.
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
%sensorFiles = {'BTSensor1_Rand_Data.txt', 'BTSensor2_Rand_Data.txt', 'BTSensor3_Rand_Data.txt', 'BTSensor4_Rand_Data.txt'};
sensorFiles = {'BTSensor1_Rand_Data_v2.txt', 'BTSensor2_Rand_Data_v2.txt', 'BTSensor3_Rand_Data_v2.txt', 'BTSensor4_Rand_Data_v2.txt'};


%%
% Sensor locations (in meters) [x, y]
sensorLocations = [0, 0;       % Sensor 1 at (0, 0)
                   5, 0;      % Sensor 2 at (5, 0)
                   0, 5;      % Sensor 3 at (0, 5)
                   5, 5];    % Sensor 4 at (5, 5)
% This means that the BT device will be at (2.5, 2.5)

% Define the update interval
updateInterval = 0.25; % 0.25 seconds

% Initialize figure for plotting
figure;
hold on;

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
    latestTime = max(combinedData.Timestamp);

    % Filter the latest data (last 0.25 seconds)
    %recentData = combinedData(combinedData.Timestamp >= latestTime - seconds(updateInterval), :);
    recentData = combinedData(combinedData.Timestamp >= latestTime, :); % Sketchy way to do this lol

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

    % Pause for the update interval
    %pause(updateInterval);
%end
