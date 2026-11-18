CREATE DATABASE IF NOT EXISTS space_debris_db;
USE space_debris_db;
DROP TABLE IF EXISTS api_logs;
DROP TABLE IF EXISTS prediction_history;
DROP TABLE IF EXISTS collision_alerts;
DROP TABLE IF EXISTS orbit_data;
DROP TABLE IF EXISTS debris;
DROP TABLE IF EXISTS satellites;
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER'
) ENGINE=InnoDB;
CREATE TABLE satellites (
    satellite_id INT AUTO_INCREMENT PRIMARY KEY,
    norad_id INT NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    operator_name VARCHAR(100),
    orbit_type VARCHAR(30),
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB;
CREATE TABLE debris (
    debris_id INT AUTO_INCREMENT PRIMARY KEY,
    norad_id INT NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    origin VARCHAR(120),
    size_m DECIMAL(8,2),
    mass_kg DECIMAL(10,2)
) ENGINE=InnoDB;
CREATE TABLE orbit_data (
    orbit_id INT AUTO_INCREMENT PRIMARY KEY,
    satellite_id INT NULL,
    debris_id INT NULL,
    epoch DATETIME NOT NULL,
    inclination DECIMAL(10,6),
    eccentricity DECIMAL(12,10),
    raan DECIMAL(10,6),
    arg_perigee DECIMAL(10,6),
    mean_motion DECIMAL(12,8),
    mean_anomaly DECIMAL(10,6),
    FOREIGN KEY (satellite_id)
        REFERENCES satellites(satellite_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (debris_id)
        REFERENCES debris(debris_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;
CREATE TABLE collision_alerts (
    alert_id INT AUTO_INCREMENT PRIMARY KEY,
    satellite_id INT NOT NULL,
    debris_id INT NOT NULL,
    prediction_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    minimum_distance_km DECIMAL(10,3) NOT NULL,
    collision_probability DECIMAL(6,4) NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    FOREIGN KEY (satellite_id)
        REFERENCES satellites(satellite_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (debris_id)
        REFERENCES debris(debris_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;
CREATE TABLE prediction_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    prediction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    algorithm VARCHAR(100) NOT NULL,
    accuracy DECIMAL(5,2),
    remarks VARCHAR(255),
    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;
CREATE TABLE api_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    api_name VARCHAR(100) NOT NULL,
    endpoint VARCHAR(255),
    request_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_status INT,
    records_received INT DEFAULT 0,
    remarks VARCHAR(255),
    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;
CREATE INDEX idx_satellite_norad ON satellites(norad_id);
CREATE INDEX idx_debris_norad ON debris(norad_id);
CREATE INDEX idx_satellite_status ON satellites(status);
CREATE INDEX idx_debris_origin ON debris(origin);
CREATE INDEX idx_orbit_epoch ON orbit_data(epoch);
CREATE INDEX idx_alert_risk ON collision_alerts(risk_level);
CREATE INDEX idx_alert_prediction_time ON collision_alerts(prediction_time);
CREATE INDEX idx_api_request_time ON api_logs(request_time);
SHOW TABLES;