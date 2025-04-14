function estimatedPosition = multilaterate(sensorLocations, distances)
    % Ensure sensorLocations and distances match
    if size(sensorLocations, 1) ~= length(distances)
        error('Mismatch: sensorLocations and distances must have the same number of entries.');
    end

    % Filter out invalid sensors (distance > 10)
    distances = distances(:);  % ensure column vector
    valid = distances <= 10;

    % Only apply filtering if valid indices match array bounds
    if sum(valid) < 3
        error('At least 3 valid sensors required.');
    end

    sensorLocations = sensorLocations(valid, :);
    distances = distances(valid);
    numSensors = size(sensorLocations, 1);

    bestError = inf;
    estimatedPosition = [NaN, NaN];

    for ref = 1:numSensors
        % Use sensor `ref` as the reference
        x1 = sensorLocations(ref, 1);
        y1 = sensorLocations(ref, 2);
        r1 = distances(ref);

        indices = setdiff(1:numSensors, ref);
        A = zeros(numSensors - 1, 2);
        B = zeros(numSensors - 1, 1);

        for k = 1:length(indices)
            i = indices(k);
            xi = sensorLocations(i, 1);
            yi = sensorLocations(i, 2);
            ri = distances(i);
            A(k, :) = 2 * [xi - x1, yi - y1];
            B(k) = r1^2 - ri^2 - x1^2 - y1^2 + xi^2 + yi^2;
        end

        % Least squares estimate for this reference
        try
            pos = A \ B;
            res = A * pos - B;
            errorNorm = norm(res);

            if errorNorm < bestError
                bestError = errorNorm;
                estimatedPosition = pos';
            end
        catch
            continue;
        end
    end
end
