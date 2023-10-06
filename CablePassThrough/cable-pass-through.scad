// parametric cable pass through
//
// Copyright Vincent Sanders 2023 <vince@kyllikki.org>
// Attribution 4.0 International (CC BY 4.0)
// Version 1.1

// https://github.com/rcolyer/threads-scad
use <threads.scad>

/* [Pass Through] */
// pass through outer diameter
pt_diameter = 60; //[10:200]

//pass through depth
pt_depth = 25; //[10:200]

// pass through flange size
pt_lip_size=5; //[2:20]

// parts to render
pt_parts = "all"; //[all,inner-outer,inner,outer,cap]

// cap style
pt_cap_style = "ring-text"; //[solid,solid-text,ring,ring-text,half,small]
//cap text
pt_cap_text = "Parametric pass through. VRS (2023)  ";

module __Customizer_Limit__ () {}

// additional wall thickness
pt_wall=1;
// depth of the flanges
pt_flange_depth=2;
// thread angle. Standard metric threads are 30 but are challenging to print
thread_angle=50;
// size of ridges (both sides)
ridge_size = 1;
// number of ridges on outer
ridge_count=8;
// height of the clips on the flange
flange_clip_size =1;
// number of clips on cap
cap_clips=4;
// width of each clip
cap_clip_size=5;

// outer diameter
pt_outer = pt_diameter - ridge_size;
thread_width = (ThreadPitch(pt_outer)/tan(thread_angle));
pt_inner = pt_outer - (thread_width/2) - pt_wall;
flange_diameter = pt_diameter +(2*pt_lip_size);
core_radius = ((pt_inner-thread_width)/2)-pt_wall;

echo(pt_diameter=pt_diameter,thread_width=thread_width,pt_outer=pt_outer,pt_inner=pt_inner,core_diameter=(core_radius*2));

// openscad detail settings
$fs = 0.1; // minimum fragment size
$fa = 2; // minimum angle

module flange(depth, diameter, hole_diameter) {
    translate([0, 0, -pt_flange_depth]) {
        difference() {
            cylinder(h=depth, r1=(diameter/2)- depth, r2=diameter/2);
            translate([0, 0, -0.1])
                cylinder(h=depth + 0.2, r1=(hole_diameter+depth)/2, r2=(hole_diameter/2));
        }
    }
}
module ridge(x,y,z) {
    polyhedron(
        //pt    0            1            2            3            4            5            6
        points=[[-x/2,-y,0], [x/2,0,0],   [-x/2,y,0],  [-x/2,-y,z], [0,0,z],     [-x/2,y,z],  [x/2,0,z/2]],
        faces=[[0,1,2], [0,3,4,6,1], [1,6,4,5,2], [0,2,5,3], [3,5,4]]
    );
}

module ridges(count) {
    ang = 360/count;
    for (step=[1:count]) {
        rotate(a=[0, 0, step * ang]) translate([(pt_outer/2), 0, 0]) ridge(ridge_size/2, ridge_size/2, pt_depth);
    }
}

module outer() {
    union() {
        flange(pt_flange_depth, flange_diameter, core_radius*2);
        ridges(ridge_count);
        ScrewHole(outer_diam=pt_inner, height=pt_depth, tooth_angle=thread_angle)
            cylinder(h=pt_depth, r=(pt_outer/2), center=false);
    }
}


module inner() {
    difference() {
        union() {
            ScrewThread(outer_diam=pt_inner, height=pt_depth, tooth_angle=thread_angle);
            flange(pt_flange_depth, flange_diameter, core_radius*2);
        }
        union() {
            translate([0,0,-0.1])
                cylinder(h=pt_depth+0.2, r=core_radius,center=false);
            cylinder(h=flange_clip_size, r1=core_radius, r2=core_radius+(flange_clip_size/2));
            translate([0,0,flange_clip_size])
                cylinder(h=flange_clip_size,  r1=core_radius+(flange_clip_size/2),r2=core_radius);
        }
    }
}

function circle_text_radius(radius,chars) = radius - ((2 * PI * radius)/len(chars));

module circle_text(radius, depth, chars) {
    lenchars = len(chars);
    font_size = (2 * PI * radius) / lenchars;
    step_angle = 360 / lenchars;

    for (char = [0 : lenchars - 1])
        rotate(a=[0, 180, char * step_angle])
            translate([0, radius + font_size / 2, -depth])
                linear_extrude(depth)
                    text(
                        chars[char],
                        font = "Liberation Mono; Style = Bold",
                        size = font_size,
                        valign = "center",
                        halign = "center"
                    );
}

// sector of a cylinder
module sector(h, d, a1, a2) {
    if (a2 - a1 > 180) {
        difference() {
            cylinder(h=h, d=d);
            translate([0,0,-0.5]) sector(h+1, d+1, a2-360, a1);
        }
    } else {
        difference() {
            cylinder(h=h, d=d);
            rotate([0,0,a1])
                translate([-d/2, -d/2, -0.5])
                    cube([d, d/2, h+1]);
            rotate([0,0,a2])
                translate([-d/2, 0, -0.5])
                    cube([d, d/2, h+1]);
        }
    }
}

module cap(depth, hole_diameter, clip_count, clip_len, style) {
    ang = 360/clip_count;
    circ = 2 * PI * (hole_diameter/2);
    clip_angle = ((clip_len/circ) * 360)/2;//half the clip arc angle
    cap_z = depth + 0.2; // additional cap height gives a small line

    // construct cap with face style
    difference() {
        translate([0, 0, -depth])
            cylinder(h=cap_z, r1=(hole_diameter+depth)/2, r2=(hole_diameter/2));
        if (style=="half")
            translate([0, 0, -depth - 0.1])
                intersection() {
                    cylinder(h=cap_z + 0.3,
                             r1=hole_diameter/2.5,
                             r2=(hole_diameter/2.5)-depth,
                             center=false,
                             $fn=30*24);
                    translate([0, -hole_diameter/2, 0])
                        cube([hole_diameter/2.5, hole_diameter, cap_z + 0.3], center=false);
                }
        else if (style=="ring")
            translate([0, 0, -depth - 0.1])
                cylinder(h=cap_z + 0.3,
                         r1=hole_diameter/2.5,
                         r2=(hole_diameter/2.5)-depth,
                         center=false,
                         $fn=30*24);
        else if (style=="small")
            translate([0, 0, -depth - 0.1])
                cylinder(h=cap_z + 0.3,
                         r1=hole_diameter/4,
                         r2=(hole_diameter/4)-depth,
                         center=false,
                         $fn=30*24);
        else if (style=="ring-text") {
            hole_radius = circle_text_radius((hole_diameter - depth)/2, pt_cap_text);
            translate([0, 0, -depth - 0.1])
                union() {
                    circle_text(hole_radius, depth/2, pt_cap_text);
                    cylinder(h=cap_z + 0.3,
                         r1=hole_radius-(depth/2),
                         r2=hole_radius-(depth/2)-depth,
                         center=false,
                         $fn=30*24);
                }
        } else if (style=="solid-text") {
            hole_radius = circle_text_radius((hole_diameter - depth)/2, pt_cap_text);
            translate([0, 0, -depth - 0.1])
                    circle_text(hole_radius, depth/2, pt_cap_text);
        }
    }

    // construct clips
    difference () {
        intersection() {
            union() {
                for (step=[1:clip_count]) {
                    sector(flange_clip_size,
                           (core_radius+flange_clip_size)*2,
                           (step * ang)-clip_angle,
                           (step * ang)+clip_angle);
                }
            }
            cylinder(h=flange_clip_size, r1=core_radius, r2=core_radius+(flange_clip_size/2));
        }
        cylinder(h=flange_clip_size, r=core_radius-flange_clip_size,center=false);
     }
}

module rndr_plate(lst) {
    for(ent=lst) {
        translate(ent[1]) {
            if (ent[0]=="inner")
                inner();
            else if (ent[0]=="outer")
                outer();
            else if (ent[0]=="cap")
                cap(pt_flange_depth, core_radius*2, cap_clips, cap_clip_size, pt_cap_style);
        }
    }
}

// main plate
plate_offset = (flange_diameter+5)/2;
if (pt_parts=="inner-outer") {
    rndr_plate([["inner",[-plate_offset,0,0]],["outer",[plate_offset,0,0]]]);
}
else if (pt_parts=="inner") {
    rndr_plate([["inner",[0,0,0]]]);
}
else if (pt_parts=="outer") {
    rndr_plate([["outer",[0,0,0]]]);
}
else if (pt_parts=="cap") {
    rndr_plate([["cap",[0,0,0]]]);
}
else { // all is default
    rndr_plate([
        ["inner",[-plate_offset, -plate_offset, 0]],
        ["outer",[ plate_offset, -plate_offset, 0]],
        ["cap",[-plate_offset, plate_offset, 0]],
        ["cap",[ plate_offset, plate_offset, 0]]
    ]);
}
