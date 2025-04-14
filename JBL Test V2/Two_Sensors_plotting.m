close all;
clear;

% MAC addresses to track
specificMAC1 = "2C:AF:33:58:6F:D1";  % Blue marker
specificMAC2 = "AA:BB:CC:DD:EE:FF";  % Red marker ← Replace this with your second MAC

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

% Update interval
updateInterval = 0.25;

% === INITIAL PLOT SETUP ===
figure;
hold on;
axis([-5 10 -5 10]);
xlabel('X Position (m)');
ylabel('Y Position (m)');
title('Real-Time Estimated Position for Specific MACs');

% Plot sensor locations
hSensors = plot(sensorLocations(:, 1), sensorLocations(:, 2), 'ro', ...
                'MarkerSize', 10, 'DisplayName', 'Sensors');

% Dummy points for legend (will not appear on plot)
hTrace1 = plot(NaN, NaN, 'bx', 'MarkerSize', 12, 'LineWidth', 2, ...
               'DisplayName', char(specificMAC1));
hTrace2 = plot(NaN, NaN, 'rx', 'MarkerSize', 12, 'LineWidth', 2, ...
               'DisplayName', char(specificMAC2));

% Lock the legend
legend([hSensors, hTrace1, hTrace2]);

% === MAIN LOOP ===
while true
    tic;

    % Combine all sensor data
    combinedData = table();

    for i = 1:length(sensorFiles)
        try
            opts = detectImportOptions(sensorFiles{i}, 'Delimiter', ',');
            opts.VariableNames = {'Timestamp', 'ID', 'Name', 'Address', 'RSSI', 'Distance'};
            opts = setvartype(opts, {'Timestamp', 'ID', 'Name', 'Address'}, 'string');
            opts = setvartype(opts, {'RSSI', 'Distance'}, 'double');

            data = readtable(sensorFiles{i}, opts);

            if height(data) == 0
                warning(['File ', sensorFiles{i}, ' is empty. Skipping.']);
                continue;
            end

            combinedData = [combinedData; data];

        catch ME
            warning(['Error reading ', sensorFiles{i}, ': ', ME.message]);
            continue;
        end
    end

    % === FIRST MAC ===
    recentData1 = combinedData(combinedData.Address == specificMAC1, :);

    if height(recentData1) >= 3
        recentData1 = sortrows(recentData1, 'ID');
        distances1 = recentData1.Distance;

        try
            estimatedPosition1 = multilateratev3_Final(sensorLocations, distances1);

            h1 = plot(estimatedPosition1(1), estimatedPosition1(2), 'bx', ...
                      'MarkerSize', 12, 'LineWidth', 2);
            h1.Annotation.LegendInformation.IconDisplayStyle = 'off';

        catch ME
            disp(['Multilateration error (MAC 1): ', ME.message]);
        end
    else
        disp("Not enough sensor data for MAC 1: " + specificMAC1);
    end

    % === SECOND MAC ===
    recentData2 = combinedData(combinedData.Address == specificMAC2, :);

    if height(recentData2) >= 3
        recentData2 = sortrows(recentData2, 'ID');
        distances2 = recentData2.Distance;

        try
            estimatedPosition2 = multilateratev3_Final(sensorLocations, distances2);

            h2 = plot(estimatedPosition2(1), estimatedPosition2(2), 'rx', ...
                      'MarkerSize', 12, 'LineWidth', 2);
            h2.Annotation.LegendInformation.IconDisplayStyle = 'off';

        catch ME
            disp(['Multilateration error (MAC 2): ', ME.message]);
        end
    else
        disp("Not enough sensor data for MAC 2: " + specificMAC2);
    end

    pause(updateInterval);
    toc;
end
