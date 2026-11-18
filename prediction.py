import math


def calculate_risk(satellite_data, debris_data):

    # Get orbital parameters
    satellite_inclination = float(
        satellite_data["inclination"]
    )

    debris_inclination = float(
        debris_data["inclination"]
    )

    satellite_eccentricity = float(
        satellite_data["eccentricity"]
    )

    debris_eccentricity = float(
        debris_data["eccentricity"]
    )

    satellite_mean_motion = float(
        satellite_data["mean_motion"]
    )

    debris_mean_motion = float(
        debris_data["mean_motion"]
    )


    # Calculate differences between the two objects
    inclination_difference = abs(
        satellite_inclination - debris_inclination
    )

    eccentricity_difference = abs(
        satellite_eccentricity - debris_eccentricity
    )

    mean_motion_difference = abs(
        satellite_mean_motion - debris_mean_motion
    )


    # Prototype orbital risk score
    gap = (
        inclination_difference / 10
        + eccentricity_difference * 1000
        + mean_motion_difference * 2
    )


    # Estimate minimum distance
    distance = 2 + (gap * 4)

    # Keep result within demo range
    distance = max(
        0.8,
        min(80.0, distance)
    )


    # Prototype probability score
    probability = math.exp(
        -distance / 18
    )

    probability = max(
        0.02,
        min(0.98, probability)
    )


    # Determine risk level
    if probability >= 0.60:

        risk_level = "HIGH"

    elif probability >= 0.25:

        risk_level = "MEDIUM"

    else:

        risk_level = "LOW"


    return {

        "minimum_distance_km":
            round(distance, 3),

        "collision_probability":
            round(probability, 4),

        "risk_level":
            risk_level
    }