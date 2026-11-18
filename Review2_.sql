USE space_debris_db;
ALTER TABLE collision_alerts
ADD CONSTRAINT chk_collision_probability
CHECK (collision_probability >= 0
AND collision_probability <= 1);

SELECT alert_id,
       satellite_id,
       debris_id,
       collision_probability
FROM collision_alerts
WHERE collision_probability BETWEEN 0 AND 1;

ALTER TABLE debris
ADD CONSTRAINT chk_debris_size
CHECK (size_m > 0);
SELECT debris_id,
       name,
       size_m
FROM debris
WHERE size_m > 0;

SELECT COUNT(*) AS total_collision_alerts
FROM collision_alerts;

SELECT AVG(collision_probability) AS average_probability
FROM collision_alerts;

SELECT MIN(minimum_distance_km) AS minimum_distance,
       MAX(minimum_distance_km) AS maximum_distance
FROM collision_alerts;

SELECT risk_level,
       COUNT(*) AS alert_count
FROM collision_alerts
GROUP BY risk_level;

SELECT origin, AVG(mass_kg) AS average_mass
FROM debris
GROUP BY origin;

SELECT satellite_id
FROM satellites
INTERSECT
SELECT satellite_id
FROM collision_alerts;

SELECT satellite_id
FROM satellites
UNION
SELECT satellite_id
FROM collision_alerts;

SELECT satellite_id
FROM satellites
EXCEPT
SELECT satellite_id
FROM collision_alerts;

SELECT name
FROM satellites
WHERE satellite_id IN
(
    SELECT satellite_id
    FROM collision_alerts
    WHERE risk_level = 'HIGH'
);

SELECT debris_id,
       name,
       mass_kg
FROM debris
WHERE mass_kg >
(
    SELECT AVG(mass_kg)
    FROM debris
);

SELECT *
FROM collision_alerts
WHERE collision_probability >
(
    SELECT AVG(collision_probability)
    FROM collision_alerts );

SELECT s.name AS satellite_name,
       c.alert_id,
       c.minimum_distance_km,
       c.collision_probability,
       c.risk_level
FROM satellites s
INNER JOIN collision_alerts c
ON s.satellite_id = c.satellite_id;

SELECT s.name AS satellite_name,
       d.name AS debris_name,
       c.minimum_distance_km,
       c.collision_probability,
       c.risk_level
FROM collision_alerts c
INNER JOIN satellites s
ON c.satellite_id = s.satellite_id
INNER JOIN debris d
ON c.debris_id = d.debris_id;

SELECT s.name AS satellite_name,
       o.epoch,
       o.inclination,
       o.eccentricity,
       o.mean_motion
FROM satellites s
INNER JOIN orbit_data o
ON s.satellite_id = o.satellite_id;

SELECT s.satellite_id,
       s.name AS satellite_name,
       c.alert_id,
       c.risk_level
FROM satellites s
LEFT JOIN collision_alerts c
ON s.satellite_id = c.satellite_id;

DROP VIEW IF EXISTS _satellite_collision_summary;
CREATE VIEW satellite_collision_summary AS
SELECT c.alert_id,
       s.name AS satellite_name,
       d.name AS debris_name,
       c.minimum_distance_km,
       c.collision_probability,
       c.risk_level,
       c.prediction_time
FROM collision_alerts c
INNER JOIN satellites s
ON c.satellite_id = s.satellite_id
INNER JOIN debris d
ON c.debris_id = d.debris_id;
SELECT *
FROM satellite_collision_summary;

DROP VIEW IF EXISTS high_risk_alerts;
CREATE VIEW high_risk_alerts AS
SELECT c.alert_id,
       s.name AS satellite_name,
       d.name AS debris_name,
       c.minimum_distance_km,
       c.collision_probability,
       c.risk_level
FROM collision_alerts c
INNER JOIN satellites s
ON c.satellite_id = s.satellite_id
INNER JOIN debris d
ON c.debris_id = d.debris_id
WHERE c.risk_level = 'HIGH';

SELECT *
FROM high_risk_alerts;

DROP VIEW IF EXISTS risk_distribution;
CREATE VIEW risk_distribution AS
SELECT risk_level,
       COUNT(*) AS alert_count
FROM collision_alerts
GROUP BY risk_level;
SELECT *
FROM risk_distribution;

DROP FUNCTION IF EXISTS GetRiskLevel;
DELIMITER //
CREATE FUNCTION GetRiskLevel(probability DECIMAL(6,4))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE result_level VARCHAR(20);
    IF probability >= 0.60 THEN
        SET result_level = 'HIGH';
    ELSEIF probability >= 0.25 THEN
        SET result_level = 'MEDIUM';
    ELSE
        SET result_level = 'LOW';
    END IF;
    RETURN result_level;
END //
DELIMITER ;
-- Testing the function:
SELECT alert_id,
       collision_probability,
       GetRiskLevel(collision_probability) AS calculated_risk
FROM collision_alerts;

DROP PROCEDURE IF EXISTS CheckRisk;
DELIMITER //
CREATE PROCEDURE CheckRisk(
    IN input_probability DECIMAL(6,4)
)
BEGIN
    DECLARE risk_result VARCHAR(20);
    IF input_probability >= 0.60 THEN
        SET risk_result = 'HIGH';
    ELSEIF input_probability >= 0.25 THEN
        SET risk_result = 'MEDIUM';
    ELSE
        SET risk_result = 'LOW';
    END IF;
SELECT risk_result AS risk_level;
END //
DELIMITER ;
-- Execution:
CALL CheckRisk(0.75);

DROP PROCEDURE IF EXISTS GetAlertsByRisk;
DELIMITER //
CREATE PROCEDURE GetAlertsByRisk(
    IN input_risk VARCHAR(20)
)
BEGIN
    SELECT *
    FROM collision_alerts
    WHERE risk_level = input_risk;
END //
DELIMITER ;
-- Execution:
CALL GetAlertsByRisk('HIGH');

DROP TRIGGER IF EXISTS after_collision_alert_insert;
DELIMITER //
CREATE TRIGGER after_collision_alert_insert
AFTER INSERT ON collision_alerts
FOR EACH ROW
BEGIN
    INSERT INTO api_logs
    (
        user_id,
        api_name,
        endpoint,
        response_status,
        records_received,
        remarks
    )
    VALUES
    (
        NULL,
        'CollisionPredictionAPI',
        '/api/predict',
        200,
        1,
        'Collision alert generated automatically'
    );
END //
DELIMITER ;
-- Testing:
INSERT INTO collision_alerts
(
    satellite_id,
    debris_id,
    minimum_distance_km,
    collision_probability,
    risk_level
)
VALUES
(
    1,
    1,
    2.500,
    0.7500,
    'HIGH'
);
-- Verification:
SELECT *
FROM api_logs
ORDER BY log_id DESC
LIMIT 1;

DROP TRIGGER IF EXISTS before_collision_alert_insert;
DELIMITER //
CREATE TRIGGER before_collision_alert_insert
BEFORE INSERT ON collision_alerts
FOR EACH ROW
BEGIN
    IF NEW.collision_probability < 0
       OR NEW.collision_probability > 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Collision probability must be between 0 and 1';
    END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS ProcessCollisionAlerts;
DELIMITER //
CREATE PROCEDURE ProcessCollisionAlerts()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE alert_id_value INT;
    DECLARE risk_value VARCHAR(20);
    DECLARE alert_cursor CURSOR FOR
        SELECT alert_id, risk_level
        FROM collision_alerts;
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET finished = 1;
    OPEN alert_cursor;
    read_loop: LOOP
        FETCH alert_cursor
        INTO alert_id_value, risk_value;

        IF finished = 1 THEN
            LEAVE read_loop;
        END IF;
        INSERT INTO api_logs
        (
            user_id,
            api_name,
            endpoint,
            response_status,
            records_received,
            remarks
        )
        VALUES
        (
            NULL,
            'CursorProcessor',
            '/api/process-alert',
            200,
            1,
            CONCAT(
                'Processed Alert ID: ',
                alert_id_value,
                ' Risk: ',
                risk_value
            )
        );
    END LOOP;
    CLOSE alert_cursor;
END //
DELIMITER ;
-- Execution:
CALL ProcessCollisionAlerts();

DROP PROCEDURE IF EXISTS ValidateProbability;
DELIMITER //
CREATE PROCEDURE ValidateProbability(
    IN input_probability DECIMAL(6,4)
)
BEGIN
    IF input_probability < 0
       OR input_probability > 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Invalid probability. Value must be between 0 and 1';
    ELSE
        SELECT 'Valid probability' AS message;
    END IF;
END //
DELIMITER ;
-- Execution:
CALL ValidateProbability(1.0);


