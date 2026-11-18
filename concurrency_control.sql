USE space_debris_db;

-- 1. Confirm storage engines (transactional tables should be InnoDB).
SELECT TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'space_debris_db'
AND TABLE_NAME IN ('users','satellites','debris','orbit_data',
                   'collision_alerts','prediction_history','api_logs');

-- 2. Display the current transaction isolation level.
SELECT @@transaction_isolation AS isolation_level;

-- 3. Set this connection to REPEATABLE READ.
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation AS isolation_level;

-- 4. COMMIT demonstration. Check that alert_id=1 exists first.
SELECT alert_id, risk_level FROM collision_alerts WHERE alert_id=1;
START TRANSACTION;
UPDATE collision_alerts SET risk_level='MEDIUM' WHERE alert_id=1;
SELECT alert_id, risk_level FROM collision_alerts WHERE alert_id=1;
COMMIT;
SELECT alert_id, risk_level FROM collision_alerts WHERE alert_id=1;

-- 5. ROLLBACK demonstration. The temporary update should be undone.
START TRANSACTION;
UPDATE collision_alerts SET risk_level='LOW' WHERE alert_id=1;
SELECT alert_id, risk_level FROM collision_alerts WHERE alert_id=1;
ROLLBACK;
SELECT alert_id, risk_level FROM collision_alerts WHERE alert_id=1;

-- 6. SAVEPOINT demonstration. Both updates are ultimately rolled back.
START TRANSACTION;
UPDATE collision_alerts SET risk_level='MEDIUM' WHERE alert_id=1;
SAVEPOINT S1;
UPDATE collision_alerts SET risk_level='LOW' WHERE alert_id=2;
ROLLBACK TO SAVEPOINT S1;
SELECT alert_id, risk_level FROM collision_alerts WHERE alert_id IN (1,2);
ROLLBACK;

-- 7. ROW-LEVEL LOCKING DEMONSTRATION: requires two separate Workbench tabs.
-- SESSION A: execute these statements and leave the transaction open:
-- START TRANSACTION;
-- SELECT alert_id, risk_level FROM collision_alerts
-- WHERE alert_id=1 FOR UPDATE;
--
-- SESSION B: while A is still open, execute:
-- START TRANSACTION;
-- UPDATE collision_alerts SET risk_level='HIGH' WHERE alert_id=1;
-- This update waits while Session A holds the row lock (unless timeout occurs).
--
-- SESSION A: release the lock:
-- COMMIT;
--
-- SESSION B: after its UPDATE completes:
-- COMMIT;
--
-- Do not execute the commented two-session instructions as one script.

-- 8. Multi-statement transaction template; rolled back at the end.
-- Requires user_id=1, satellite_id=1, and debris_id=1 to exist.
START TRANSACTION;
INSERT INTO collision_alerts
(satellite_id, debris_id, minimum_distance_km,
 collision_probability, risk_level)
SELECT 1, 1, 3.500, 0.4500, 'MEDIUM'
WHERE EXISTS (SELECT 1 FROM satellites WHERE satellite_id=1)
AND EXISTS (SELECT 1 FROM debris WHERE debris_id=1);

INSERT INTO prediction_history
(user_id, algorithm, accuracy, remarks)
SELECT 1, 'Prototype Rule-Based Risk Scoring', NULL,
       'Concurrency-control demonstration'
WHERE EXISTS (SELECT 1 FROM users WHERE user_id=1);
ROLLBACK;

-- 9. Final inspection.
SELECT alert_id, satellite_id, debris_id, risk_level
FROM collision_alerts ORDER BY alert_id;

SELECT history_id, user_id, algorithm, remarks
FROM prediction_history ORDER BY history_id DESC LIMIT 10;
