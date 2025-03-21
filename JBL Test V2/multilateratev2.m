function estimatedPosition = multilateratev2(sensorLocations, distances)
    % Inputs:
    % sensorLocations: Nx2 matrix of sensor coordinates (x, y)
    % distances: Nx1 vector of distances from the target to each sensor
    %
    % Output:
    % estimatedPosition: 1x2 vector [x, y] representing the estimated position of the target

    % Filter out sensors with invalid distances (> 10 meters)
    validIndices = distances <= 10;
    sensorLocations = sensorLocations(validIndices, :);
    distances = distances(validIndices);

    % Check that we have at least 3 valid sensors
    numSensors = size(sensorLocations, 1);
    if numSensors < 3
        error('At least 3 valid sensors (distance ≤ 10 meters) are required for multilateration.');
    end

    % Initialize matrices for the linear system
    A = zeros(numSensors - 1, 2); % Coefficients for x and y
    B = zeros(numSensors - 1, 1); % Right-hand side

    % Use the first sensor as the reference
    x1 = sensorLocations(1, 1);
    y1 = sensorLocations(1, 2);
    r1 = distances(1);

    for i = 2:numSensors
        xi = sensorLocations(i, 1);
        yi = sensorLocations(i, 2);
        ri = distances(i);

        % Construct the linear equations from the range differences
        A(i - 1, :) = 2 * [xi - x1, yi - y1];
        B(i - 1) = r1^2 - ri^2 - x1^2 - y1^2 + xi^2 + yi^2;
    end

    % Solve using least squares (works for 3 or more sensors)
    estimatedPosition = A \ B; % Returns [x; y]
end
