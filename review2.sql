USE space_debris_db;

-- 1. Queries and Subqueries 

-- 1.1 Simple SELECT query
SELECT * FROM satellites;

-- 1.2 WHERE condition
SELECT * FROM satellites
WHERE status = 'ACTIVE';

-- 1.3 ORDER BY
SELECT * FROM debris
ORDER BY mass_kg DESC;

-- 1.4 Aggregate query
SELECT COUNT(*) AS total_collision_alerts,
       AVG(collision_probability) AS average_probability,
       MIN(minimum_distance_km) AS minimum_distance,
       MAX(minimum_distance_km) AS maximum_distance
FROM collision_alerts;

-- 1.5 GROUP BY
SELECT risk_level, COUNT(*) AS alert_count
FROM collision_alerts
GROUP BY risk_level;

-- 1.6 Subquery - satellites involved in HIGH-risk alerts
SELECT name
FROM satellites
WHERE satellite_id IN
(
    SELECT satellite_id
    FROM collision_alerts
    WHERE risk_level = 'HIGH'
);

-- 1.7 Subquery - alerts above average probability
SELECT *
FROM collision_alerts
WHERE collision_probability >
(
    SELECT AVG(collision_probability)
    FROM collision_alerts
);

-- 1.8 Subquery - debris heavier than average
SELECT *
FROM debris
WHERE mass_kg >
(
    SELECT AVG(mass_kg)
    FROM debris
);


-- 2. Nested and Correlated Queries 

-- 2.1 Nested query - satellites with HIGH-risk alerts
SELECT name
FROM satellites
WHERE satellite_id IN
(
    SELECT satellite_id
    FROM collision_alerts
    WHERE risk_level = 'HIGH'
);

-- 2.2 Nested query - debris involved in alerts
SELECT name
FROM debris
WHERE debris_id IN
(
    SELECT debris_id
    FROM collision_alerts
);

-- 2.3 Multi-level nested query
SELECT name
FROM satellites
WHERE satellite_id IN
(
    SELECT satellite_id
    FROM collision_alerts
    WHERE collision_probability >
    (
        SELECT AVG(collision_probability)
        FROM collision_alerts
        WHERE risk_level = 'HIGH'
    )
);

-- 2.4 Correlated query - satellites having collision alerts
SELECT s.name
FROM satellites s
WHERE EXISTS
(
    SELECT 1
    FROM collision_alerts c
    WHERE c.satellite_id = s.satellite_id
);

-- 2.5 Correlated query - debris involved in alerts
SELECT d.name
FROM debris d
WHERE EXISTS
(
    SELECT 1
    FROM collision_alerts c
    WHERE c.debris_id = d.debris_id
);

-- 2.6 Correlated query - satellites having HIGH-risk alerts
SELECT s.name
FROM satellites s
WHERE EXISTS
(
    SELECT 1
    FROM collision_alerts c
    WHERE c.satellite_id = s.satellite_id
    AND c.risk_level = 'HIGH'
);

-- 2.7 Correlated query with NOT EXISTS
SELECT s.name
FROM satellites s
WHERE NOT EXISTS
(
    SELECT 1
    FROM collision_alerts c
    WHERE c.satellite_id = s.satellite_id
);


-- 3. VIEW and JOIN - 5 Marks

-- 3.1 INNER JOIN - satellite and collision alert
SELECT s.name AS satellite_name,
       c.alert_id,
       c.minimum_distance_km,
       c.collision_probability,
       c.risk_level
FROM satellites s
INNER JOIN collision_alerts c
ON s.satellite_id = c.satellite_id;

-- 3.2 Multiple table JOIN
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

-- 3.3 JOIN satellite with orbit data
SELECT s.name AS satellite_name,
       o.epoch,
       o.inclination,
       o.eccentricity,
       o.mean_motion
FROM satellites s
INNER JOIN orbit_data o
ON s.satellite_id = o.satellite_id;

-- 3.4 LEFT JOIN
SELECT s.satellite_id,
       s.name AS satellite_name,
       c.alert_id,
       c.risk_level
FROM satellites s
LEFT JOIN collision_alerts c
ON s.satellite_id = c.satellite_id;

-- 3.5 Create VIEW
DROP VIEW IF EXISTS satellite_collision_summary;

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

-- Display VIEW
SELECT * FROM satellite_collision_summary;

-- 3.6 Create HIGH-risk VIEW
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

-- Display HIGH-risk VIEW
SELECT * FROM high_risk_alerts;


-- 4. PL/SQL

-- 4.1 Procedure with variable and IF condition
DROP PROCEDURE IF EXISTS CheckRisk;

DELIMITER //

CREATE PROCEDURE CheckRisk(IN input_probability DECIMAL(6,4))
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

-- Execute procedure
CALL CheckRisk(0.75);

-- 4.2 Stored function
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

-- Test function
SELECT alert_id,
       collision_probability,
       GetRiskLevel(collision_probability) AS calculated_risk
FROM collision_alerts;


-- 5. Trigger, Cursor and Procedures 

-- 5.1 Stored procedure
DROP PROCEDURE IF EXISTS GetHighRiskAlerts;

DELIMITER //

CREATE PROCEDURE GetHighRiskAlerts()
BEGIN
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
END //

DELIMITER ;

-- Execute procedure
CALL GetHighRiskAlerts();

-- 5.2 Parameterized procedure
DROP PROCEDURE IF EXISTS GetAlertsByRisk;

DELIMITER //

CREATE PROCEDURE GetAlertsByRisk(IN input_risk VARCHAR(20))
BEGIN
    SELECT *
    FROM collision_alerts
    WHERE risk_level = input_risk;
END //

DELIMITER ;

-- Execute procedure
CALL GetAlertsByRisk('HIGH');

-- 5.3 Trigger
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

-- 5.4 Cursor
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

-- Execute cursor procedure
CALL ProcessCollisionAlerts();