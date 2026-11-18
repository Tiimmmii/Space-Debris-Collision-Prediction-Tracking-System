USE space_debris_db;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE api_logs;
TRUNCATE TABLE prediction_history;
TRUNCATE TABLE collision_alerts;
TRUNCATE TABLE orbit_data;
TRUNCATE TABLE debris;
TRUNCATE TABLE satellites;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO users (name, email, password, role) VALUES
('Admin', 'admin@space.local', 'admin123', 'ADMIN'),
('Aarav Sharma', 'aarav@space.local', 'aarav123', 'USER'),
('Priya Singh', 'priya@space.local', 'priya123', 'USER'),
('Rahul Das', 'rahul@space.local', 'rahul123', 'USER'),
('Ananya Roy', 'ananya@space.local', 'ananya123', 'USER'),
('Rohan Mehta', 'rohan@space.local', 'rohan123', 'USER'),
('Neha Kapoor', 'neha@space.local', 'neha123', 'USER');

INSERT INTO satellites
(norad_id, name, operator_name, orbit_type, status)
VALUES
(25544, 'ISS (ZARYA)', 'NASA', 'LEO', 'ACTIVE'),
(20580, 'HUBBLE SPACE TELESCOPE', 'NASA', 'LEO', 'ACTIVE'),
(43013, 'IRIDIUM-150', 'Iridium', 'LEO', 'ACTIVE'),
(28654, 'CARTOSAT-2', 'ISRO', 'LEO', 'ACTIVE'),
(39086, 'GSAT-7', 'ISRO', 'GEO', 'ACTIVE'),
(27424, 'GPS IIR-2', 'USSF', 'MEO', 'ACTIVE'),
(33591, 'NOAA-19', 'NOAA', 'LEO', 'ACTIVE');

INSERT INTO debris
(norad_id, name, origin, size_m, mass_kg)
VALUES
(33772, 'COSMOS 2251 DEB', 'COSMOS 2251', 0.25, 15.50),
(34427, 'IRIDIUM 33 DEB', 'IRIDIUM 33', 0.18, 8.20),
(40001, 'FENGYUN 1C DEB', 'FENGYUN 1C', 0.30, 20.10),
(40002, 'COSMOS FRAGMENT A', 'COSMOS 2251', 0.12, 4.80),
(40003, 'IRIDIUM FRAGMENT B', 'IRIDIUM 33', 0.20, 9.60),
(40004, 'FENGYUN FRAGMENT C', 'FENGYUN 1C', 0.35, 25.40),
(40005, 'ROCKET BODY FRAGMENT', 'Rocket Body', 0.15, 6.30);

INSERT INTO orbit_data
(
    satellite_id,
    debris_id,
    epoch,
    inclination,
    eccentricity,
    raan,
    arg_perigee,
    mean_motion,
    mean_anomaly
)
VALUES
(1, NULL, '2026-09-08 00:00:00', 51.640000, 0.000400, 120.100000, 80.200000, 15.490000, 10.500000),
(2, NULL, '2026-09-08 01:00:00', 28.470000, 0.000300, 210.400000, 110.000000, 15.090000, 220.000000),
(3, NULL, '2026-09-08 02:00:00', 86.400000, 0.000200, 45.200000, 60.000000, 14.700000, 130.000000),
(4, NULL, '2026-09-08 03:00:00', 97.800000, 0.001000, 75.200000, 45.000000, 14.200000, 180.000000),
(NULL, 1, '2026-09-08 04:00:00', 51.700000, 0.000450, 121.000000, 81.000000, 15.480000, 12.000000),
(NULL, 2, '2026-09-08 05:00:00', 28.900000, 0.000350, 212.000000, 109.000000, 15.080000, 218.000000),
(NULL, 3, '2026-09-08 06:00:00', 97.000000, 0.001000, 70.000000, 20.000000, 13.900000, 80.000000);

INSERT INTO collision_alerts
(
    satellite_id,
    debris_id,
    prediction_time,
    minimum_distance_km,
    collision_probability,
    risk_level
)
VALUES
(1, 1, '2026-09-08 10:30:00', 4.200, 0.7800, 'HIGH'),
(2, 2, '2026-09-08 11:15:00', 18.600, 0.2100, 'MEDIUM'),
(3, 3, '2026-09-08 12:00:00', 35.400, 0.1200, 'LOW'),
(4, 4, '2026-09-08 12:45:00', 7.800, 0.6400, 'HIGH'),
(1, 5, '2026-09-08 13:30:00', 14.500, 0.3800, 'MEDIUM'),
(2, 6, '2026-09-08 14:15:00', 42.700, 0.0800, 'LOW'),
(3, 7, '2026-09-08 15:00:00', 5.600, 0.7100, 'HIGH');

INSERT INTO prediction_history
(user_id, prediction_date, algorithm, accuracy, remarks)
VALUES
(1, '2026-09-08 09:00:00', 'Prototype Orbital Risk Score', NULL, 'Initial demonstration prediction'),
(2, '2026-09-08 09:15:00', 'Prototype Orbital Risk Score', NULL, 'Satellite-debris risk assessment'),
(3, '2026-09-08 09:30:00', 'Prototype Orbital Risk Score', NULL, 'Low risk prediction'),
(4, '2026-09-08 09:45:00', 'Prototype Orbital Risk Score', NULL, 'High risk prediction'),
(5, '2026-09-08 10:00:00', 'Prototype Orbital Risk Score', NULL, 'Medium risk prediction'),
(6, '2026-09-08 10:15:00', 'Prototype Orbital Risk Score', NULL, 'Debris monitoring prediction'),
(7, '2026-09-08 10:30:00', 'Prototype Orbital Risk Score', NULL, 'Collision risk assessment');

INSERT INTO api_logs
(
    user_id,
    api_name,
    endpoint,
    request_time,
    response_status,
    records_received,
    remarks
)
VALUES
(1, 'Satellite API', '/api/satellites', '2026-09-08 09:00:00', 200, 7, 'Satellite data retrieved'),
(1, 'Debris API', '/api/debris', '2026-09-08 09:05:00', 200, 7, 'Debris data retrieved'),
(1, 'Alert API', '/api/alerts', '2026-09-08 09:10:00', 200, 7, 'Collision alerts retrieved'),
(2, 'Satellite API', '/api/satellites', '2026-09-08 09:20:00', 200, 7, 'Satellite information requested'),
(3, 'Prediction API', '/api/predict', '2026-09-08 09:30:00', 200, 1, 'Prediction request processed'),
(4, 'Prediction API', '/api/predict', '2026-09-08 09:45:00', 200, 1, 'Risk assessment completed'),
(5, 'Alert API', '/api/alerts', '2026-09-08 10:00:00', 200, 7, 'Alert records retrieved');

UPDATE satellites
SET status = 'UNDER OBSERVATION'
WHERE satellite_id = 3;

UPDATE debris
SET size_m = 0.28,
    mass_kg = 17.50
WHERE debris_id = 1;

UPDATE collision_alerts
SET risk_level = 'HIGH',
    collision_probability = 0.8500
WHERE alert_id = 2;

UPDATE prediction_history
SET remarks = 'Prediction reviewed by administrator'
WHERE history_id = 1;

ALTER TABLE users
MODIFY role VARCHAR(30) NOT NULL DEFAULT 'USER';

ALTER TABLE satellites
MODIFY name VARCHAR(150) NOT NULL;

ALTER TABLE debris
MODIFY origin VARCHAR(150);

ALTER TABLE api_logs
MODIFY remarks VARCHAR(300);

SELECT * FROM users;
SELECT * FROM satellites;
SELECT * FROM debris;
SELECT * FROM orbit_data;
SELECT * FROM collision_alerts;
SELECT * FROM prediction_history;
SELECT * FROM api_logs;