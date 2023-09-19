# Name: Calculate coordinates of rotated images' corners
# Author: ultrapre@github.com
# Version: 1.0
# License: Public Domain
# Description: 
# This script simplifies the process by allowing you to rotate the corners of an image based on a specified rotation angle and celestial center.
# To use this script, you'll need to import the provided coord module, which contains celestial coordinate utilities. The main functionality is encapsulated in the following functions:
# calculate_rotated_corners(centre, x, y, alpha): Calculates the coordinates of the four corners of a rotated image based on the center point, a vector (x, y), and the rotation angle alpha.
# rotate_coordinates(center, coord2, angle_degrees, distance): Rotates celestial coordinates around a specified center point.
# normalize_vector(u): Normalizes a 3D vector to a unit vector.


from coord import *
import math

class unit:
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z
    def __init__(self, lis):
        self.x = lis[0]
        self.y = lis[1]
        self.z = lis[2]


def normalize_vector(u):
    x,y,z = u
    length = math.sqrt(x**2 + y**2 + z**2)
    return (x / length, y / length, z / length)


def rotate_coordinates(center, coord2, angle_degrees, distance):
    # Step 1: Calculate unit vector u from center to coord2
    vect = tuple(t1 - t2 for t1, t2 in zip(coord2.get_xyz(), center.get_xyz()))
    vect = unit(vect)

    # Step 2: Calculate unit vector u (same direction as center)
    u = unit(normalize_vector(center.get_xyz()))

    # Step 3: Calculate coord3's coordinates
    # Convert angle from degrees to radians
    angle_radians = math.radians(angle_degrees)

    # Calculate the rotation matrix
    cos_angle = math.cos(angle_radians)
    sin_angle = math.sin(angle_radians)
    rotation_matrix = [
        [cos_angle + (1 - cos_angle) * u.x**2, (1 - cos_angle) * u.x * u.y - sin_angle * u.z, (1 - cos_angle) * u.x * u.z + sin_angle * u.y],
        [(1 - cos_angle) * u.y * u.x + sin_angle * u.z, cos_angle + (1 - cos_angle) * u.y**2, (1 - cos_angle) * u.y * u.z - sin_angle * u.x],
        [(1 - cos_angle) * u.z * u.x - sin_angle * u.y, (1 - cos_angle) * u.z * u.y + sin_angle * u.x, cos_angle + (1 - cos_angle) * u.z**2]
    ]

    # Apply the rotation matrix to center's coordinates to get coord3's coordinates
    coord3_coordinates = [
        rotation_matrix[0][0] * vect.x + rotation_matrix[0][1] * vect.y + rotation_matrix[0][2] * vect.z,
        rotation_matrix[1][0] * vect.x + rotation_matrix[1][1] * vect.y + rotation_matrix[1][2] * vect.z,
        rotation_matrix[2][0] * vect.x + rotation_matrix[2][1] * vect.y + rotation_matrix[2][2] * vect.z
    ]

    # Create and return the coord3 object
    coord3 = CelestialCoord.from_xyz(*coord3_coordinates)
    coord4 = center.greatCirclePoint(coord3, distance * degrees)
    return coord4


# Rotate clockwise by alpha
# centre: centre's coord of image
# x, y: length, width of image
# alpha: rotate angle
def calculate_rotated_corners(centre, x, y, alpha):
    # Calculate beta, the angle between (x, y) and the x-axis in degrees
    beta = math.degrees(math.atan(y/x))

    # Calculate the distance from the center to the corners (diameter/2)
    d = math.sqrt(x**2 + y**2) / 2

    # Define the North Pole as a reference point (zenith)
    z0 = CelestialCoord(0*degrees, 90*degrees)

    # Calculate the coordinates of four corners after rotation
    A = rotate_coordinates(centre, z0, 90 - beta + alpha, d)
    B = rotate_coordinates(centre, z0, 90 + beta + alpha, d)
    C = rotate_coordinates(centre, z0, 270 - beta + alpha, d)
    D = rotate_coordinates(centre, z0, 270 + beta + alpha, d)

    return A, B, C, D  # Return the coordinates of the four corners




if __name__=='__main__':
    a1 = CelestialCoord(338.2334583 * degrees, -88.55028611 * degrees)
    x,y = 10,8
    alpha = -195
    a,b,c,d = list(calculate_rotated_corners(a1,x,y,alpha))
    z0 = CelestialCoord(0*degrees,90*degrees)

    print(a.ra.deg,a.dec.deg)
    print(b.ra.deg,b.dec.deg)
    print(c.ra.deg,c.dec.deg)
    print(d.ra.deg,d.dec.deg)

    print(a1.angleBetween(z0,a).deg)
    print(a1.angleBetween(z0,b).deg)
    print(a1.angleBetween(z0,c).deg)
    print(a1.angleBetween(z0,d).deg)

    print(a.distanceTo(b).deg)
    print(b.distanceTo(c).deg)
    print(c.distanceTo(d).deg)
    print(d.distanceTo(a).deg)
