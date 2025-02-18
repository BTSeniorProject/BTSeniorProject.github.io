function estimatedPosition = multilaterate(sensorLocations, distances)
    % Inputs:
    % sensorLocations: Nx2 matrix of sensor coordinates (x, y)
    % distances: Nx1 vector of distances from the target to each sensor
    %
    % Output:
    % estimatedPosition: 1x2 vector [x, y] representing the estimated position of the target
    
    % Ensure we have at least 3 sensors
    if size(sensorLocations, 1) < 3 || length(distances) < 3
        error('At least 3 sensors are required for multilateration.');
    end
    
    % Number of sensors
    numSensors = size(sensorLocations, 1);
    
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

        % Construct the equations (from distance differences)
        A(i - 1, :) = 2 * [xi - x1, yi - y1];
        B(i - 1) = r1^2 - ri^2 - x1^2 - y1^2 + xi^2 + yi^2;
    end

    % Solve the linear system using the least-squares method
    estimatedPosition = A \ B; % Returns [x; y]
end
