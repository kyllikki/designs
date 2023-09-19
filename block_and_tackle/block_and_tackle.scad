// block and tackle using bearings
//
// Copyright Vincent Sanders 2023 <vince@kyllikki.org>
// Attribution 4.0 International (CC BY 4.0)
// Version 1.1

// Type of block
block_type = "single"; // [single,double,triple,quadruple,quintuple]

// diameter of cable/rope being used
cable_diameter = 4;// [2:10]

// code for bearing in use
bearing_code = 608;// [625,608,609,6000,6002,6004,6902]

// axel bolt size (nominal diameter) (bearing - use bearing bore)
axle_size = "bearing"; // [bearing,5,8,10,12,20]

// whether the wheels in the block have side guards 
block_guards = true;

/* [first block] */

// first plate first support bolt size (nominal diameter) (axle - use axle size)
support_1_1_size = "axle"; // [axle,5,8,10,12,20]

// first plate second support bolt size (nominal diameter) (none - no support) (same - use first support size) 
support_1_2_size = "same"; // [none,same,5,8,10,12,20]

/* [second block] */
// second plate first support bolt size (nominal diameter) (none - no second block) (axle - use axle size)
support_2_1_size = "axle"; // [none,axle,5,8,10,12,20]

// second plate second support bolt size (nominal diameter) (none - no support) (same - use first support size) 
support_2_2_size = "none"; // [none,same,5,8,10,12,20]

module __Customizer_Limit__ () {}

wheel_clearance = 0.6;// clerance between wheel and block
wheel_additional_diameter = 4; // material between the bearing and the base of the cable groove
plate_thickness = 2.2;// thickness of plate walls
block_guard_size = 2;

// openscad detail settings
$fs = 0.1; // minimum fragment size
$fa = 2; // minimum angle

// name to number map
name_count_map = [["single",1],["double",2],["triple",3],["quadruple",4],["quintuple",5]];
function NameToNumber(name) = [for (x = name_count_map) if (x[0] == name) x[1]][0];

// data for bearings
// [code, [bore, shoulder, recess, outer, width]]
bearing_data = [
    [608,  [8,  12.5,  19.2, 22,  7]],
    [609,  [9, 14.45,  21.2, 24,  7]],
    [625,  [5,  8.4,  13.22, 16,  5]],
    [6000, [10, 14.8,  22.6, 26,  8]], 
    [6002, [15, 20.5,  28.2, 32,  9]], 
    [6004, [20, 27.2, 37.19, 42, 12]],
    [6902, [15,   17,    26, 28,  7]]
];

function BearingData(code) = _table_search(bearing_data, code, 608);

// nut and bolt sizes used for axle
m5_bolt_lengths=[22,25,30,35,40,45,50,55,60,65];
m8_bolt_lengths=[22,25,30,35,40,45,50,55,60,65,70,75,80];
m10_bolt_lengths=[25,30,35,40,50,60,70,80,90,100];
m12_bolt_lengths=[25,30,35,40,50,55,60,65,70,75,80, 85,90,100,110];
m20_bolt_lengths=[30,35,40,50,55,60,65,70,75,80,90,100,110];
// bearing bore, [diameter, [lengths], nut flats, nut height]
bolt_data = [
[5,  [ 5, m5_bolt_lengths, 8, 5]],
[8,  [ 8, m8_bolt_lengths, 13, 8]],
[9,  [ 8, m8_bolt_lengths, 13, 8]],
[10, [10, m10_bolt_lengths, 17, 10]],// DIN
[12, [12, m12_bolt_lengths, 19, 12]], // DIN
[15, [12, m12_bolt_lengths, 19, 12]],// DIN
[20, [20, m20_bolt_lengths, 30, 20]],
];
function BoltData(bore) = _table_search(bolt_data, bore, 5);

// select bolt length from available sizes
//TODO: if nothing is found return passed in length instead of undef
function _select_bolt_len(minlen, boltlen) = [for(n=boltlen) if (n >= minlen) n][0];

// search a table with a default value
function _table_search(table, term, default) = 
    _table_search_idx(table, search(term, table)[0], search(default, table)[0]);
function _table_search_idx(table, index, default_index) = 
    (is_undef(index) ? table[default_index][1] : table[index][1]);

module torus(radius,tube_radius) {
    rotate_extrude(convexity = 5)        
        translate([radius, 0, 0])
            circle(r = tube_radius);
}

module bearing_placeholder(bearing) {
    bearing_bore = bearing[0];
    bearing_shoulder = bearing[1];
    bearing_recess = bearing[2];
    bearing_outer = bearing[3];
    bearing_width = bearing[4];
    race_size = 0.5; // the size of the race indent
    difference() {
        rotate_extrude(convexity = 5)
            polygon([
                [bearing_bore/2,0], 
                [bearing_bore/2,bearing_width], 
                [bearing_shoulder/2,bearing_width],
                [bearing_shoulder/2,bearing_width-race_size],
                [bearing_recess/2,bearing_width-race_size],
                [bearing_recess/2,bearing_width],
                [bearing_outer/2,bearing_width],
                [bearing_outer/2,0],
                [bearing_recess/2,0],
                [bearing_recess/2,race_size],
                [bearing_shoulder/2,race_size],
                [bearing_shoulder/2,0]
            ]);
        translate([0,0,-0.1]) cylinder(h=bearing_width+0.2,r=bearing_bore/2, center=false);    
    }
}

function geta1(r1, r2, k) = k*r2/(r2 - r1);
function getAlpha(opposite_side = 1, hypothenuse = 1) = asin(opposite_side/hypothenuse);

// join two circles using external tangents
// https://gieseanw.wordpress.com/2012/09/12/finding-external-tangent-points-for-two-circles/
module tangent_join(radiusa, radiusb, length, height) {
    
    // ensure radius1 is the largest
    radius1 = (radiusa > radiusb) ? radiusa : radiusb;
    radius2 = (radiusa > radiusb) ? radiusb : radiusa;
    
    // compute the tangent triangle
    radius3 = radius1 - radius2;
    tangent_length = sqrt((length*length) - (radius3 * radius3));
    
    split_length = sqrt((tangent_length * tangent_length) + (radius2 * radius2));
    theta = acos(((radius1 * radius1)+(length*length)-(split_length*split_length)) / (2 * radius1 * length) );
    
    x1=radius1 * cos(theta);
    y1=radius1 * sin(theta);
    x2=length + radius2 * cos(theta);
    y2=radius2 * sin(theta);
    
    // Points that make the trapezoid
    point0 = [x1, y1];
    point1 = [x2, y2];
    point2 = [x2, -y2];
    point3 = [x1, -y1];

    linear_extrude(height=height) polygon(points=[point0, point1, point2, point3], paths=[[0,1,2,3]]);
}

// calculate wheel height ensuring there are always guides at least 2.5mm either side of cable
// bearing_height = bearing[4]
function calc_wheel_height(bearing, cable_diameter) = max((bearing[4] + 2), (cable_diameter + 5));

// the diameter of the wheel side guides
function calc_wheel_guide_diameter(bearing, cable_diameter) = 
    (calc_wheel_height(bearing, cable_diameter) - cable_diameter) / 2;

// calculate wheel radius
// bearing_outer = bearing[3];
// bearing radius + extra bearing diameter + cable radius + guide side radius
// TODO : cable radius vs cable diameter, i think the side guides are a cable radius too tall?
function calc_wheel_radius(bearing, cable_diameter) =
    (bearing[3] + 
     wheel_additional_diameter + 
     calc_wheel_guide_diameter(bearing, cable_diameter)
    ) / 2 + cable_diameter;

// create plate and support on one side of the axle
module support(wheel_radius, wheel_height, bolt, bolt_length, outer) {
    bolt_flat_radius = bolt[2]/2;
    bolt_radius = bolt[0]/2;
    center = wheel_radius + wheel_clearance + bolt_flat_radius;
    boss_height = wheel_height/2 + wheel_clearance;
    guard_radius = (block_guards? block_guard_size: 0);
    
    difference() {
        union() {
            // tangent polygon            
            translate([0,0,outer ? 0 : boss_height])
                tangent_join(wheel_radius + wheel_clearance+guard_radius,
                             bolt_flat_radius,
                             center,
                             plate_thickness);
            // tip of the plate
            translate([center,0,0]) {
                cylinder(h=(outer ? 0 : boss_height) + plate_thickness + boss_height,
                         r=bolt_flat_radius,
                         center=false);
            }
        }
        translate([center,0,-0.01]) cylinder(h=bolt_length,r=bolt_radius,center=false);
    }
}

// guard sides
module block_guards(radius, height) {
    cut_angle=45;
    difference() {
        cylinder(h=height, r=radius, center=false);
        union() {
            cylinder(h=height + 0.01, r=radius - block_guard_size, center=false);
            rotate([0,0,-(cut_angle/2)]) cube([radius, radius,height+0.01], center=false);
            rotate([0,0,90+(cut_angle/2)]) cube([radius, radius,height+0.01], center=false);
            rotate([0,0,-90+(cut_angle/2)]) cube([radius, radius,height+0.01], center=false);
            rotate([0,0,180-(cut_angle/2)]) cube([radius, radius,height+0.01], center=false);
        }
    }
}

// plate center and bearing abutments
module center(wheel_radius, wheel_height, bearing, bolt,support1,support2,bolt_length,outer) {
    bearing_bore = bearing[0];
    bearing_shoulder = bearing[1];
    bearing_width = bearing[4];
    bearing_gap = bearing[2] - bearing[1];// gap between bearing recess and shoulder
    abutment_radius = (bearing_shoulder + bearing_gap/3)/2;
    abutment_height = 1 + wheel_clearance;
    bolt_sleeve_radius = (bolt[0] < bearing_bore ? bearing_bore/2 : 0);
    bolt_sleeve_height= bearing_width/2;
    bolt_radius = bolt[0]/2;
    boss_height = wheel_height/2 + wheel_clearance;
    guard_radius = (block_guards? block_guard_size: 0);

    difference() {
        translate([0,0,outer ? 0 : boss_height]) {
            //%translate([0,0,plate_thickness+wheel_clearance]) wheel(bearing, cable_diameter);
            // center disc
                difference() {
                    cylinder(h=plate_thickness, r=wheel_radius + wheel_clearance + guard_radius, center=false);
                    union() {
                        // center disc can interfere with support bolts
                        translate([wheel_radius + wheel_clearance +(support1[2]/2),0,-0.01]) 
                            cylinder(h=bolt_length,r=support1[0]/2,center=false);
                        if (!is_undef(support2))
                            translate([-wheel_radius - wheel_clearance -(support2[2]/2),0,-0.01]) 
                                cylinder(h=bolt_length,r=support2[0]/2,center=false);
                    }
                }

                // block guards
                if (block_guards)
                    block_guards(wheel_radius + wheel_clearance + guard_radius, plate_thickness + boss_height);

                // center abutment
                translate([0,0,outer?0:-abutment_height])
                    cylinder(h=(outer?0:abutment_height) +plate_thickness + abutment_height,
                             r=abutment_radius,
                             center=false);
                
                // make bearing fit on bolt with sleeve if required
                if (bolt_sleeve_radius > 0) 
                    translate([0,0,outer?0:-abutment_height-bolt_sleeve_height])
                        cylinder(h=(outer?0:bolt_sleeve_height+abutment_height)+
                                       plate_thickness + abutment_height + bolt_sleeve_height,
                                 r=bolt_sleeve_radius,
                                 center=false);
        }
        
        translate([0,0,-0.01]) cylinder(h=bolt_length,r=bolt_radius,center=false);
    }
}    

// bolt holes
module blockboltholes() {
    //axle
    translate([0,0,-0.01]) cylinder(h=bolt_length,r=bolt_radius,center=false);
                         translate([wheel_radius + wheel_clearance +(support1[2]/2),0,-0.01]) 
                            cylinder(h=bolt_length,r=support1[0]/2,center=false);
                        if (!is_undef(support2))
                            translate([-wheel_radius - wheel_clearance -(support2[2]/2),0,-0.01]) 
                                cylinder(h=bolt_length,r=support2[0]/2,center=false);   
}

// outer side of block
module blockouter(bearing, axle, support1, support2, cable_diameter, wheel_radius, bolt_length, outer) {
    wheel_height = calc_wheel_height(bearing, cable_diameter);
    
    difference() {
        union() {
            // center
            center(wheel_radius, wheel_height, bearing, axle, support1,support2,bolt_length, outer);

            // first support
            support(wheel_radius, wheel_height, support1, bolt_length, outer);

            // second support
            if (!is_undef(support2))
                rotate([0,0,180])
                    support(wheel_radius, wheel_height, support2, bolt_length, outer);
        }
        //blockboltholes();
    }
}

// pulley wheel
module wheel(bearing, groove_diameter) {
    difference() {
        bearing_shoulder = bearing[1];
        bearing_recess = bearing[2];
        bearing_outer = bearing[3];
        bearing_width = bearing[4];
        bearing_gap = bearing[2] - bearing[1];// gap between bearing recess and shoulder

        height = calc_wheel_height(bearing, groove_diameter);
        side_height = (height - groove_diameter) / 2;
        guide_height = calc_wheel_guide_diameter(bearing, groove_diameter);
        
        groove_radius = ((bearing_outer + wheel_additional_diameter + groove_diameter) / 2);
        
        union() {
            //main disc
            cylinder(h=height, r=groove_radius + (groove_diameter / 2), center=false);
            //grove sides
            translate([0, 0, side_height / 2])
                torus(groove_radius + groove_diameter / 2, side_height / 2);
            translate([0, 0, height - (side_height / 2)])
                torus(groove_radius + groove_diameter / 2, side_height / 2);
        }
        union() {
            // bearing space
            translate([0,0,(height - bearing_width)/2])
                cylinder(h=height, r=bearing_outer/2, center=false,$fn=30*24);
            // bearing bore
            translate([0,0,-0.1])
                cylinder(h=height+0.2, r=(bearing_recess - bearing_gap/3)/2, center=false);
            // groove
            translate([0,0,height / 2])
                rotate_extrude(convexity = 10, $fn = 100)
                    translate([groove_radius, 0, 0])
                        union() {   
                            circle(r = groove_diameter / 2, $fn = 100);
                            translate([0,-groove_diameter/2,0]) square([groove_diameter*2,groove_diameter], center=false);
                        }
        }
        translate([0,0,(height-bearing_width)/2]) %bearing_placeholder(bearing);
    }
}


function toInt(s, ret=0, i=0) = i >= len(s) ? ret: toInt(s, ret*10 + ord(s[i]) - ord("0"), i+1);
    
// generate a list if shaft sizes based on configuration
function calc_shafts(bearing) =
    let(axle = BoltData(axle_size == "bearing" ? bearing[0]:toInt(axle_size)),
        support1 = (support_1_1_size == "axle" ? axle : BoltData(toInt(support_1_1_size))),
        support2 = (support_1_2_size == "none" ? undef : 
                       (support_1_2_size == "same" ? support1 : 
                           BoltData(toInt(support_1_2_size)))),
        support3 = (support_2_1_size == "none" ? undef :
                       (support_2_1_size == "axle" ? axle : BoltData(toInt(support_2_1_size)))),
        support4 = (support_2_2_size == "none" ? undef : 
                       (support_2_2_size == "same" ? support3 : 
                           BoltData(toInt(support_2_2_size))))
    )
    [axle, support1, support2,support3,support4];

// compute a real bolt length from those available
function calc_bolt_length(bolt, bearing, cable_diameter,pulley_count) = 
    _select_bolt_len(bolt[3] + 
                         plate_thickness + 
                         (pulley_count * 
                             (calc_wheel_height(bearing, cable_diameter) + 
                                 wheel_clearance + 
                                 wheel_clearance +
                                 plate_thickness)),
                     bolt[1]);


// pulley components in a print plate
module plate(bearing, pulley_count) {
    echo(bearing=bearing, pulley_count=pulley_count);

    shafts = calc_shafts(bearing);      
    echo(len(shafts), shafts=shafts);

    wheel_radius = calc_wheel_radius(bearing, cable_diameter);
    echo(wheel_radius =wheel_radius);
    
    bolt_length = calc_bolt_length(shafts[0], bearing, cable_diameter, pulley_count);
    echo(bolt_length =bolt_length);

    // pulley wheels for both blocks
    total_pulley_count = (is_undef(shafts[3]) ? pulley_count: 2*pulley_count);
    for (i=[1:total_pulley_count]) 
        translate([(i-(is_undef(shafts[3]) ? 1:2)) * (wheel_radius + 4) * 2, 0 ,0])
            wheel(bearing, cable_diameter);
    
    // block sides
    for (blk=[0:(is_undef(shafts[3]) ? 0:1)]) {
        mult = (blk==0?-1:1);
    for (i=[0:pulley_count]) 
        translate([(i * (wheel_radius + 4) * 2)-wheel_radius, mult *wheel_radius*3, 0]) {
            rotate([0,0,90*mult*-1])
                    blockouter(
                        bearing,
                        shafts[0],
                        shafts[(blk*2)+1],
                        shafts[(blk*2)+2],
                        cable_diameter,
                        wheel_radius,
                        bolt_length,
                        ((i == 0)||(i==pulley_count))
                    );
    }    
    }


}

plate(BearingData(bearing_code), NameToNumber(block_type));

