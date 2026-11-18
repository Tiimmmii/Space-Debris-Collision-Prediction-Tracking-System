-- Inspect keys, constraints, and table definitions.
SHOW CREATE TABLE users;
SHOW CREATE TABLE satellites;
SHOW CREATE TABLE debris;
SHOW CREATE TABLE orbit_data;
SHOW CREATE TABLE collision_alerts;
SHOW CREATE TABLE prediction_history;
SHOW CREATE TABLE api_logs;

-- Verify atomic orbital observation records (1NF).
SELECT orbit_id, satellite_id, debris_id, epoch, inclination,
       eccentricity, raan, arg_perigee, mean_motion, mean_anomaly
FROM orbit_data ORDER BY orbit_id;

-- Verify independent satellite and debris relations (2NF/3NF).
SELECT * FROM satellites ORDER BY satellite_id;
SELECT * FROM debris ORDER BY debris_id;

-- Verify collision alerts reference existing satellite and debris records.
SELECT c.alert_id, s.name AS satellite_name, d.name AS debris_name,
       c.minimum_distance_km, c.collision_probability, c.risk_level
FROM collision_alerts c
JOIN satellites s ON s.satellite_id = c.satellite_id
JOIN debris d ON d.debris_id = c.debris_id
ORDER BY c.alert_id;

-- Referential-integrity checks: each count should be zero.
SELECT COUNT(*) AS orphan_orbit_satellite_refs
FROM orbit_data o LEFT JOIN satellites s
ON o.satellite_id = s.satellite_id
WHERE o.satellite_id IS NOT NULL AND s.satellite_id IS NULL;

SELECT COUNT(*) AS orphan_orbit_debris_refs
FROM orbit_data o LEFT JOIN debris d
ON o.debris_id = d.debris_id
WHERE o.debris_id IS NOT NULL AND d.debris_id IS NULL;

SELECT COUNT(*) AS orphan_alert_satellite_refs
FROM collision_alerts c LEFT JOIN satellites s
ON c.satellite_id = s.satellite_id
WHERE s.satellite_id IS NULL;

SELECT COUNT(*) AS orphan_alert_debris_refs
FROM collision_alerts c LEFT JOIN debris d
ON c.debris_id = d.debris_id
WHERE d.debris_id IS NULL;

SELECT COUNT(*) AS orphan_prediction_user_refs
FROM prediction_history p LEFT JOIN users u
ON p.user_id = u.user_id
WHERE u.user_id IS NULL;

-- NULL user_id is allowed for system-generated API logs.
SELECT COUNT(*) AS orphan_api_log_user_refs
FROM api_logs a LEFT JOIN users u
ON a.user_id = u.user_id
WHERE a.user_id IS NOT NULL AND u.user_id IS NULL;

-- Row counts for all seven relations.
SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users
UNION ALL SELECT 'satellites', COUNT(*) FROM satellites
UNION ALL SELECT 'debris', COUNT(*) FROM debris
UNION ALL SELECT 'orbit_data', COUNT(*) FROM orbit_data
UNION ALL SELECT 'collision_alerts', COUNT(*) FROM collision_alerts
UNION ALL SELECT 'prediction_history', COUNT(*) FROM prediction_history
UNION ALL SELECT 'api_logs', COUNT(*) FROM api_logs;
