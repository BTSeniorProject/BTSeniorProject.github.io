close all;
clear;

% MAC address to track
specificMAC = "2C:AF:33:58:6F:D1";

% List of sensor files
sensorFiles = {'Btbluetooth1_scan_data.txt', ...
               'Btbluetooth2_scan_data.txt', ...
               'Btbluetooth3_scan_data.txt', ...
               'Btbluetooth4_scan_data.txt'};

% Sensor locations [x, y]
sensorLocations = [0, 0;
                   5, 0;
                   0, 5;
                   5, 5];

% Real-time update interval (s)
updateInterval = 0.25;

% === INITIAL PLOT SETUP ===
figure;
hold on;
axis([-5 10 -5 10]);
xlabel('X Position (m)');
ylabel('Y Position (m)');
title('Real-Time Estimated Position for Specific MAC');

% Plot sensor locations once
hSensors = plot(sensorLocations(:, 1), sensorLocations(:, 2), 'ro', ...
                'MarkerSize', 10, 'DisplayName', 'Sensors');

% Dummy trace point for legend entry
hFirstTrace = plot(NaN, NaN, 'bx', 'MarkerSize', 12, 'LineWidth', 2, ...
                   'DisplayName', char(specificMAC));

% Lock legend to these two handles only
legend([hSensors, hFirstTrace]);

while true
    tic;

    % Combine sensor data from all files
    combinedData = table();
    for i = 1:length(sensorFiles)
        while true
            try
                opts = detectImportOptions(sensorFiles{i}, 'Delimiter', ',');
                opts.VariableNames = {'Timestamp', 'ID', 'Name', 'Address', 'RSSI', 'Distance'};
                opts = setvartype(opts, {'Timestamp', 'ID', 'Name', 'Address'}, 'string');
                opts = setvartype(opts, {'RSSI', 'Distance'}, 'double');

                data = readtable(sensorFiles{i}, opts);

                if height(data) > 0
                    break;
                else
                    disp(['File ', sensorFiles{i}, ' is empty. Waiting for data...']);
                end
            catch ME
                disp(['Error reading ', sensorFiles{i}, ': ', ME.message]);
            end
            pause(0.1);
        end
        combinedData = [combinedData; data];
    end

    % Filter for the tracked MAC
    recentData = combinedData(combinedData.Address == specificMAC, :);

    if height(recentData) >= 3
        recentData = sortrows(recentData, 'ID');
        distances = recentData.Distance;

        try
            estimatedPosition = multilateratev3_Final(sensorLocations, distances);

            % Plot new point, but exclude it from the legend
            h = plot(estimatedPosition(1), estimatedPosition(2), 'bx', ...
                     'MarkerSize', 12, 'LineWidth', 2);
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';

        catch ME
            disp(['Multilateration error: ', ME.message]);
        end
    else
        disp("Not enough sensor data for MAC: " + specificMAC);
    end

    pause(updateInterval);
    toc;
end
