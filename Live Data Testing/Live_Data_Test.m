close all; % Close all figures
clear;

% List of sensor files
sensorFiles = {'Btbluetooth_scan_data_1.txt', ...
               'Btbluetooth_scan_data_2.txt', ...
               'Btbluetooth_scan_data_3.txt', ...
               'Btbluetooth_scan_data_4.txt'};

% Sensor locations (in meters) [x, y]
sensorLocations = [0, 0;  % Sensor 1 at (0, 0)
                   5, 0;  % Sensor 2 at (5, 0)
                   0, 5;  % Sensor 3 at (0, 5)
                   5, 5]; % Sensor 4 at (5, 5)

% Define real-time update interval (seconds)
updateInterval = 0.25;

% Infinite loop for real-time tracking
while true
    tic
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

    % Get all unique MAC addresses from the latest scan
    uniqueMACs = unique(combinedData.Address);

    % Define colors for different MAC addresses
    colors = lines(length(uniqueMACs)); % Generates distinguishable colors

    % Clear previous plot
    clf;
    
    % Plot sensor locations
    plot(sensorLocations(:, 1), sensorLocations(:, 2), 'ro', 'MarkerSize', 10, 'DisplayName', 'Sensors');
    axis([0 5 0 5])
    hold on;

    % Process each MAC address
    for k = 1:length(uniqueMACs)
        targetMAC = uniqueMACs(k);

        % Filter for the target MAC address
        recentData = combinedData(combinedData.Address == targetMAC, :);

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
    title('Real-Time Estimated Positions');
    legend('show');

    % Pause before the next loop iteration
    pause(updateInterval);
    toc
end
