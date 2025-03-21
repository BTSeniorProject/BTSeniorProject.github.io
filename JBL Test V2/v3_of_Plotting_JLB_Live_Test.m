close all; % Close all figures
clear;

% MAC address to track
specificMAC = "2C:FD:B4:74:97:7E"; % <-- Replace with the MAC you want

% List of sensor files
sensorFiles = {'Btbluetooth_scan_data_1.txt', ...
               'Btbluetooth_scan_data_2.txt', ...
               'Btbluetooth_scan_data_3.txt', ...
               'Btbluetooth_scan_data_4.txt'};

% Sensor locations (in meters) [x, y]
sensorLocations = [0, 0;  
                   5, 0;  
                   0, 5;  
                   5, 5]; 

% Define real-time update interval (seconds)
updateInterval = 0.25;

while true
    tic
    % Read and combine sensor data
    combinedData = table();

    for i = 1:length(sensorFiles)
        while true
            try
                % Try to get import options
                opts = detectImportOptions(sensorFiles{i}, 'Delimiter', ',');
                opts.VariableNames = {'Timestamp', 'ID', 'Name', 'Address', 'RSSI', 'Distance'};
                opts = setvartype(opts, {'Timestamp', 'ID', 'Name', 'Address'}, 'string'); 
                opts = setvartype(opts, {'RSSI', 'Distance'}, 'double'); 

                % Try to read the file
                data = readtable(sensorFiles{i}, opts);

                % If the file is successfully read and has data, break out of the retry loop
                if height(data) > 0
                    break;
                else
                    disp(['File ', sensorFiles{i}, ' is empty. Waiting for data...']);
                end

            catch ME
                disp(['Error reading ', sensorFiles{i}, ': ', ME.message]);
            end
            pause(0.1); % Short delay before retrying
        end

        % Append valid data
        combinedData = [combinedData; data];
    end

    % Clear previous plot
    clf; % Comment this out to hold the previous data

    % Plot sensor locations
    plot(sensorLocations(:, 1), sensorLocations(:, 2), 'ro', 'MarkerSize', 10, 'DisplayName', 'Sensors');
    axis([0 5 0 5])
    hold on;

    % Filter for the specific MAC address
    recentData = combinedData(combinedData.Address == specificMAC, :);

    % Proceed only if at least 3 sensors reported this MAC
    if height(recentData) >= 3
        % Sort by sensor ID (assuming sensors have unique IDs)
        recentData = sortrows(recentData, 'ID'); 

        % Extract distances
        distances = recentData.Distance; 

        % Perform multilateration safely
        try
            estimatedPosition = multilateratev2(sensorLocations, distances);

            % Plot estimated position for this MAC address
            plot(estimatedPosition(1), estimatedPosition(2), 'bx', 'MarkerSize', 12, 'LineWidth', 2, ...
                'DisplayName', char(specificMAC));
            axis([-5 10 -5 10])
        catch ME
            disp(['Multilateration error: ', ME.message]);
        end
    else
        disp("Not enough sensor data for MAC: " + specificMAC);
    end

    xlabel('X Position (m)');
    ylabel('Y Position (m)');
    title('Real-Time Estimated Position for Specific MAC');
    legend('show');

    pause(updateInterval);
    toc
end
