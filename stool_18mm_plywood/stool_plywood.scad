/* -*- mode: scad; c-basic-offset: 4; c-file-style: "k&r"; indent-tabs-mode: nil -*- */

/**
 * \file stool_plywood.scad A parametric design of a plywood stool.
 * Render it with CGAL and export to DXF for milling.
 */

/*
 * Variables:
 *
 * Change these to taste.
 */

plywood_thickness = 18;         /**< the thicknes of your plywood sheet */
number_of_legs = 3;             /**< the number of legs you'd like your stool had */

/*
 * Constants:
 *
 * If I were you I wouldn't touch these. These values were carefuly
 * calculated, there are many dependencies between them. The changes
 * you make to any of these may not be properly reflected in other
 * values.
 * 
 */
eps = .1;                       /**< "a bit" */

mill_tool_dia = 6;              /**< the diameter of the milling tool */

leg_angle = 75;                 /**< the angle between a leg and the floor */
leg_angles = [0 : 360 / number_of_legs : 359]; /**< angles at which leggs are placed under the stool */
leg_base_width = 90;            /**< the width of legs measured parallel to the floor  */
leg_length = 584;               /**< the length of the leg from the floor to the bottom of the seat along the edge of the leg */

seat_socket_radius = 30;        /**< the distance between the center of the seat and the inner sockets */
seat_socket_width = leg_base_width / 3; /**< the size of a socket along the x axis */

seat_radius = 175;              /**< the radius of the seat */

base_ring_width = 50;           /**< the width of the base ring */
base_ring_inner_radius = seat_radius + 2 * mill_tool_dia + 3; /**< the inner radius of the base ring */
base_ring_outer_radius = base_ring_inner_radius + base_ring_width; /**< the outer radius of the base ring */

/**
 * The "hole" part of joints.
 */
module socket (width = seat_socket_width, height = plywood_thickness - 2 * eps)
{
    $fn = 20;
    cr = mill_tool_dia / 2;
    translate([0, -plywood_thickness / 2, 0])
        union()
    {
        square([width, height]);
        translate([cr,         0]) circle(r = cr);
        translate([width - cr, 0]) circle(r = cr);
        translate([cr,         height]) circle(r = cr);
        translate([width - cr, height]) circle(r = cr);
    }
}

/**
 * The base ring that keeps the legs together.
 */
module base_ring ()
{
    difference()
    {
        circle (r = base_ring_outer_radius, $fn = 100);
        circle (r = base_ring_inner_radius, $fn = 100);
        for (a = leg_angles)
            rotate([0, 0, a]) 
                translate ([base_ring_inner_radius - 10, 0, 0])
                socket (25 + 10);
    }
}

/**
 * The seat
 */ 
module seat()
{
    difference()
    {
        circle (r = seat_radius, $fn = 100);
        for (a = leg_angles)
            rotate ([0, 0, a])
                translate ([seat_socket_radius, 0, 0])
                union()
            {
                socket ();
                translate ([2 * seat_socket_width, 0, 0])
                    socket();
            }
    }
}

/**
 * A single leg.
 */
module leg() {
    leg_width = leg_base_width * sin(leg_angle);
    leg_height = leg_length * sin(leg_angle);
    leg_length_straight = leg_length + leg_base_width * cos(leg_angle);
    leg_rectangle_width = leg_base_width + leg_length * cos(leg_angle) + 2 * eps;
    base_ring_socket_height = leg_height - (base_ring_outer_radius - (seat_socket_radius + leg_base_width)) * tan(leg_angle) - 0.5 * plywood_thickness;
    base_ring_socket_depth = (base_ring_socket_height + 0.5 * plywood_thickness) / tan(leg_angle);
    union ()
    {
        difference ()
        {
            intersection ()
            {
                translate ([-eps, 0])
                    square ([leg_rectangle_width, leg_height]);
                rotate ([0, 0, leg_angle - 90])
                    square ([leg_width, leg_length_straight]);
            }
            /* 40 - 15 = 25 the actual depth of the socket at the upper edge */
            translate ([-15+base_ring_socket_depth, base_ring_socket_height]) socket(width=40);
            /* adjust the leg below the ring */
            rotate ([0, 0, leg_angle - 90])
                 translate ([-eps, 0])
                 square ([eps + (plywood_thickness * cos(75)), base_ring_socket_height]);
        }
        translate ([leg_length * cos(leg_angle), leg_height])
            difference ()
        {
            square ([leg_base_width, plywood_thickness - 2*eps]);
            translate ([leg_base_width / 3, plywood_thickness])
                socket(width=leg_base_width / 3, height=plywood_thickness);
        }
    }
}

/**
 * Appropriate number of properly spaced legs.
 */
module legs ()
{
    for (i = [0 : 1 : number_of_legs - 1])
        translate([i * (leg_base_width + 2 * mill_tool_dia + 3), 0]) leg();
}

if (1)
{
    translate([base_ring_outer_radius, base_ring_outer_radius])
    {
        base_ring();
        seat();
    }
    translate([2*base_ring_outer_radius - 30, 0]) legs();
}
else
{
    echo ("DEBUG");
}
