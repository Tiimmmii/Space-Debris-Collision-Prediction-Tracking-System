from flask import Flask, jsonify, request
from flask_cors import CORS
from database import get_connection
from prediction import calculate_risk
from datetime import datetime
app = Flask(__name__)
CORS(app)
# HELPER FUNCTION
def fetch_all(query, params=()):

    connection = get_connection()

    cursor = connection.cursor(
        dictionary=True
    )

    cursor.execute(
        query,
        params
    )

    result = cursor.fetchall()

    cursor.close()
    connection.close()

    return result

# HOME / SERVER STATUS
@app.route("/")
def home():

    return jsonify({
        "message":
            "Space Debris Collision Prediction DBMS API",

        "status":
            "running"
    })


# ============================================================
# DASHBOARD STATISTICS
# ============================================================

@app.route("/api/stats")
def stats():

    result = fetch_all("""
        SELECT

            (SELECT COUNT(*)
             FROM satellites)
             AS satellites,

            (SELECT COUNT(*)
             FROM debris)
             AS debris,

            (SELECT COUNT(*)
             FROM collision_alerts)
             AS alerts,

            (SELECT COUNT(*)
             FROM collision_alerts
             WHERE risk_level = 'HIGH')
             AS high_risk
    """)

    return jsonify(result[0])


# ============================================================
# GET SATELLITES
# ============================================================

@app.route("/api/satellites")
def get_satellites():

    satellites = fetch_all("""
        SELECT
            *
        FROM satellites
        ORDER BY satellite_id
    """)

    return jsonify(satellites)


# ============================================================
# GET DEBRIS
# ============================================================

@app.route("/api/debris")
def get_debris():

    debris = fetch_all("""
        SELECT
            *
        FROM debris
        ORDER BY debris_id
    """)

    return jsonify(debris)


# ============================================================
# GET COLLISION ALERTS
# ============================================================

@app.route("/api/alerts")
def get_alerts():

    alerts = fetch_all("""
        SELECT

            c.alert_id,

            s.name AS satellite,

            d.name AS debris,

            c.prediction_time,

            c.minimum_distance_km,

            c.collision_probability,

            c.risk_level

        FROM collision_alerts c

        JOIN satellites s
            ON c.satellite_id =
               s.satellite_id

        JOIN debris d
            ON c.debris_id =
               d.debris_id

        ORDER BY
            c.alert_id DESC
    """)

    return jsonify(alerts)


# ============================================================
# COLLISION PREDICTION
# ============================================================

@app.route(
    "/api/predict",
    methods=["POST"]
)
def predict():

    # --------------------------------------------------------
    # Get data from frontend
    # --------------------------------------------------------

    data = request.get_json()

    satellite_id = int(
        data["satellite_id"]
    )

    debris_id = int(
        data["debris_id"]
    )


    # --------------------------------------------------------
    # Get satellite orbital data
    # --------------------------------------------------------

    satellite_data = fetch_all("""

        SELECT

            s.name,

            o.inclination,

            o.eccentricity,

            o.mean_motion

        FROM satellites s

        JOIN orbit_data o

            ON s.satellite_id =
               o.satellite_id

        WHERE s.satellite_id = %s

        LIMIT 1

    """, (satellite_id,))


    # --------------------------------------------------------
    # Get debris orbital data
    # --------------------------------------------------------

    debris_data = fetch_all("""

        SELECT

            d.name,

            o.inclination,

            o.eccentricity,

            o.mean_motion

        FROM debris d

        JOIN orbit_data o

            ON d.debris_id =
               o.debris_id

        WHERE d.debris_id = %s

        LIMIT 1

    """, (debris_id,))


    # --------------------------------------------------------
    # Check whether orbital data exists
    # --------------------------------------------------------

    if not satellite_data:

        return jsonify({
            "error":
                "Satellite orbital data not found"
        }), 404


    if not debris_data:

        return jsonify({
            "error":
                "Debris orbital data not found"
        }), 404


    satellite = satellite_data[0]

    debris = debris_data[0]


    # --------------------------------------------------------
    # Calculate risk
    # --------------------------------------------------------

    result = calculate_risk(
        satellite,
        debris
    )


    # ========================================================
    # STORE COLLISION ALERT
    # ========================================================

    connection = get_connection()

    cursor = connection.cursor()


    cursor.execute("""

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
        (%s, %s, %s, %s, %s, %s)

    """, (

        satellite_id,

        debris_id,

        datetime.now(),

        result[
            "minimum_distance_km"
        ],

        result[
            "collision_probability"
        ],

        result[
            "risk_level"
        ]
    ))


    connection.commit()


    alert_id = cursor.lastrowid


    cursor.close()
    connection.close()


    # ========================================================
    # STORE PREDICTION HISTORY
    # ========================================================

    connection = get_connection()

    cursor = connection.cursor()


    # For the demo we use user_id = 1
    # (Admin user from our sample data)

    cursor.execute("""

        INSERT INTO prediction_history

        (
            user_id,
            prediction_date,
            algorithm,
            accuracy,
            remarks
        )

        VALUES
        (%s, %s, %s, %s, %s)

    """, (

        1,

        datetime.now(),

        "Prototype Orbital Risk Score",

        None,

        "Collision risk assessment performed"
    ))


    connection.commit()


    cursor.close()
    connection.close()


    # ========================================================
    # STORE API LOG
    # ========================================================

    connection = get_connection()

    cursor = connection.cursor()


    cursor.execute("""

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
        (%s, %s, %s, %s, %s, %s, %s)

    """, (

        1,

        "Internal Prediction API",

        "/api/predict",

        datetime.now(),

        200,

        1,

        "Prototype collision prediction request"
    ))


    connection.commit()


    cursor.close()
    connection.close()


    # ========================================================
    # RETURN RESULT TO FRONTEND
    # ========================================================

    return jsonify({

        "alert_id":
            alert_id,

        "satellite":
            satellite["name"],

        "debris":
            debris["name"],

        "minimum_distance_km":
            result[
                "minimum_distance_km"
            ],

        "collision_probability":
            result[
                "collision_probability"
            ],

        "risk_level":
            result[
                "risk_level"
            ],

        "note":
            "Prototype orbital risk assessment. "
            "Future versions can use real TLE data "
            "and SGP4 propagation."
    })


# ============================================================
# RUN FLASK SERVER
# ============================================================

if __name__ == "__main__":

    app.run(
        debug=True,
        port=5000
    )