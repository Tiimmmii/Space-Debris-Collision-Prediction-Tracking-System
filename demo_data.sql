USE space_debris_db;
INSERT INTO users (name,email,password,role) VALUES
('Admin','admin@space.local','admin123','ADMIN'),
('Demo User','demo@space.local','demo123','USER');
INSERT INTO satellites (norad_id,name,operator_name,orbit_type,status) VALUES
(25544,'ISS (ZARYA)','NASA','LEO','ACTIVE'),
(20580,'HUBBLE SPACE TELESCOPE','NASA','LEO','ACTIVE'),
(43013,'IRIDIUM-150','Iridium','LEO','ACTIVE');
INSERT INTO debris (norad_id,name,origin,size_m,mass_kg) VALUES
(33772,'COSMOS 2251 DEB','COSMOS 2251',0.25,15.50),
(34427,'IRIDIUM 33 DEB','IRIDIUM 33',0.18,8.20),
(40001,'FENGYUN 1C DEB','FENGYUN 1C',0.30,20.10);
INSERT INTO orbit_data
(satellite_id,debris_id,epoch,inclination,eccentricity,raan,arg_perigee,mean_motion,mean_anomaly)
VALUES
(1,NULL,'2026-09-06 00:00:00',51.64,0.000400,120.10,80.20,15.49,10.50),
(2,NULL,'2026-09-06 00:00:00',28.47,0.000300,210.40,110.00,15.09,220.00),
(3,NULL,'2026-09-06 00:00:00',86.40,0.000200,45.20,60.00,14.70,130.00),
(NULL,1,'2026-09-06 00:00:00',51.70,0.000450,121.00,81.00,15.48,12.00),
(NULL,2,'2026-09-06 00:00:00',28.90,0.000350,212.00,109.00,15.08,218.00),
(NULL,3,'2026-09-06 00:00:00',97.00,0.001000,70.00,20.00,13.90,80.00);
INSERT INTO collision_alerts
(satellite_id,debris_id,prediction_time,minimum_distance_km,collision_probability,risk_level)
VALUES
(1,1,'2026-09-08 10:30:00',4.200,0.7800,'HIGH'),
(2,2,'2026-09-08 14:15:00',18.600,0.2100,'MEDIUM');
INSERT INTO prediction_history (user_id,algorithm,accuracy,remarks) VALUES
(1,'Prototype Orbital Risk Score',NULL,'Initial demonstration prediction'),
(2,'Prototype Orbital Risk Score',NULL,'Demo prediction run');
INSERT INTO api_logs
(user_id,api_name,endpoint,response_status,records_received,remarks)
VALUES
(1,'Satellite API','/api/satellites',200,3,'Satellite data retrieved'),
(1,'Debris API','/api/debris',200,3,'Debris data retrieved'),
(1,'Alert API','/api/alerts',200,2,'Collision alerts retrieved');

USE space_debris_db;
SELECT * FROM users;
SELECT * FROM satellites;
SELECT * FROM debris;
SELECT * FROM orbit_data;
SELECT * FROM collision_alerts;
SELECT * FROM prediction_history;
SELECT * FROM api_logs;