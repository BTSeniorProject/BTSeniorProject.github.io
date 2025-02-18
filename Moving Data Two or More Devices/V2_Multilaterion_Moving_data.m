% % % Multilateration Using a Moving Point
% % %
% % % This code will use four sensors in different corners of a square shape
% % % in order to find the the location of a BT device.
% % %
% % % ------> The X's will represent sensors (Rasp. Pi) and the O will
% % %         represent the BT device emitting MAC/RSSI signals. Each
% % %         device will we be 5 meters apart. Using Pythageraon theorm,
% % %         it is obvious that the distance from the BT device to each
% % %         sensor will be 7.071 meters apart. *(Actually 3.905 meters)*
% % %
% % %                   |     X         X     |
% % %                   |                     |
% % %                   |          O          |
% % %                   |                     |
% % %                   |     X         X     |
% % %

close all; % Close all figures
clear;

% List of sensor files
sensorFiles = {'BTSensor1_Moving_Data_2_Devices.txt', ...
               'BTSensor2_Moving_Data_2_Devices.txt', ...
               'BTSensor3_Moving_Data_2_Devices.txt', ...
               'BTSensor4_Moving_Data_2_Devices.txt'};

% Sensor locations (in meters) [x, y]
sensorLocations = [0, 0;  % Sensor 1 at (0, 0)
                   5, 0;  % Sensor 2 at (5, 0)
                   0, 5;  % Sensor 3 at (0, 5)
                   5, 5]; % Sensor 4 at (5, 5)

% Define update interval (seconds)
updateInterval = 1;

% Read and combine sensor data
combinedData = table();
for i = 1:length(sensorFiles)
    % Define import options for reading the file
    opts = detectImportOptions(sensorFiles{i}, 'Delimiter', ',');
    opts.VariableNames = {'Timestamp', 'ID', 'Name', 'Address', 'RSSI', 'Distance'};
    opts = setvartype(opts, {'Timestamp', 'ID', 'Name', 'Address'}, 'string'); 
    opts = setvartype(opts, {'RSSI', 'Distance'}, 'double'); 
    
    % Read file into a table
    data = readtable(sensorFiles{i}, opts);

    % Append to combinedData
    combinedData = [combinedData; data];
end

% Convert Timestamp to datetime for easier processing
combinedData.Timestamp = datetime(combinedData.Timestamp, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS');
combinedData.Timestamp.Format = 'yyyy-MM-dd HH:mm:ss.SSS';

% Get unique timestamps in ascending order
uniqueTimestamps = unique(combinedData.Timestamp);

% Get all unique MAC addresses
uniqueMACs = unique(combinedData.Address);

% Define colors for different MAC addresses
colors = lines(length(uniqueMACs)); % Generates distinguishable colors

% Process each timestamp
for j = 1:length(uniqueTimestamps)
    latestTime = uniqueTimestamps(j);

    % Clear previous plot
    clf;
    
    % Plot sensor locations
    plot(sensorLocations(:, 1), sensorLocations(:, 2), 'ro', 'MarkerSize', 10, 'DisplayName', 'Sensors');
    axis([0 5 0 5])
    hold on;

    % Process each MAC address
    for k = 1:length(uniqueMACs)
        targetMAC = uniqueMACs(k);

        % Filter for the target MAC address at this timestamp
        recentData = combinedData(combinedData.Timestamp == latestTime & combinedData.Address == targetMAC, :);

        % Ensure we have data from all four sensors
        if height(recentData) == 4
            % Sort by sensor ID (assuming sensors have unique IDs)
            recentData = sortrows(recentData, 'ID'); 

            % Extract distances
            distances = recentData.Distance; 
            
            % Perform multilateration
            estimatedPosition = multilaterate(sensorLocations, distances);

            % Plot estimated position for this MAC address
            plot(estimatedPosition(1), estimatedPosition(2), 'x', 'MarkerSize', 12, 'LineWidth', 2, ...
                'Color', colors(k, :), 'DisplayName', char(targetMAC));
        end
    end

    % Add labels and legend
    xlabel('X Position (m)');
    ylabel('Y Position (m)');
    title(sprintf('Estimated Positions at Time: %s', datestr(latestTime)));
    legend('show');

    % Pause for visualization
    pause(updateInterval);
end

