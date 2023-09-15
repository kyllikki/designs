// block and tackle using bearings
//
// Copyright Vincent Sanders 2023 <vince@kyllikki.org>
// Attribution 4.0 International (CC BY 4.0)
// Version 1.0

type = "single"; // [single,double,triple,quadruple]

bearing_code = 608;// [625,608,609,6000,6002,6004,6902]

cable_diameter = 4;// [2:10]

// bolt size (nominal diameter) (0 - use bearing bore)
bolt_size = 0; // [0,5,8,10,15,20]

module __Customizer_Limit__ () {}

wheel_clearance = 0.6;// clerance between wheel and block
plate_thickness = 2.2;// thickness of plate walls

$fs = 0.2; // minimum fragment size
$fa = 4; // minimum angle


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
m8_bolt_lengths=[20,22,25,30,35,40,45,50,55,60,65,70,75,80];
// bearing bore, [diameter, [lengths], nut flats, nut height]
bolt_data = [
[5,  [ 5, [30                            ], 8, 5]],
[8,  [ 8, m8_bolt_lengths, 13, 8]],
[9,  [ 8, m8_bolt_lengths, 13, 8]],
[10, [10, [30                            ], 17, 10]],// DIN
[15, [15, [30                            ], 22, 14]],// DIN
[20, [20, [30                            ], 40, 20]],
];
function BoltData(bore) = _table_search(bolt_data, bore, 5);
// select bolt length from available sizes
//TODO: if nothing is found return passed in length instead of undef
function _select_bolt_len(minlen, boltlen) = [for(n=boltlen) if (n >= minlen) n][0];


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

    cylinder(h=height,r=radiusa,center=false);
    translate([length,0,0]) cylinder(h=height,r=radiusb,center=false);
    linear_extrude(height=height) polygon(points=[point0, point1, point2, point3], paths=[[0,1,2,3]]);
}

// bosses on block
module block_bosses(boss_x,
                    boss_height,
                    boss_radius,
                    abutment_height,
                    abutment_radius,
                    bolt_sleeve_height,
                    bolt_sleeve_radius)
{
    //echo(boss_x, boss_height, boss_radius, abutment_height,abutment_radius, bolt_sleeve_height, bolt_sleeve_radius);
    // support bolt sleeve
    translate([boss_x,0,0])
        cylinder(h=boss_height, r=boss_radius, center=false, $fn=30*24);
    // support bolt sleave
    translate([-boss_x,0,0])
        cylinder(h=boss_height, r=boss_radius, center=false, $fn=30*24);
     
    // center abutment
    cylinder(h=abutment_height, r=abutment_radius, center=false, $fn=30*24);
    // make bearing fit on bolt with sleeve if required
    if (bolt_sleeve_radius > 0) 
        translate([0,0,abutment_height])
            cylinder(h=bolt_sleeve_height, r=bolt_sleeve_radius, center=false, $fn=30*24);

}

// outer side of block
module blockouter(bearing, bolt, cable_diameter, wheel_radius, wheel_height, bolt_length, outer) {
    bearing_bore = bearing[0];
    bearing_shoulder = bearing[1];
    bearing_width = bearing[4];
    bearing_gap = bearing[2] - bearing[1];// gap between bearing recess and shoulder
    
    bolt_diameter = bolt[0];

    extra_radius=2;// covering round bolt bore
    tip_radius = bolt_diameter/2 + extra_radius;// radius of the cylinders at the tips
    centers = wheel_radius + wheel_clearance + tip_radius; // distance between shaft centers
    abutment_radius = (bearing_shoulder + bearing_gap/3)/2;
    bolt_sleeve_radius = (bolt_diameter < bearing_bore ? bearing_bore/2 : 0);

    
    difference() {
        translate([0,0,outer ? 0 : wheel_height/2 + wheel_clearance])
    union() {
        // plate
        tangent_join(wheel_radius, tip_radius, centers, plate_thickness);        
        tangent_join(wheel_radius, tip_radius, -centers, plate_thickness);
        if (!outer) {
            rotate([180,0,0])
            block_bosses(centers, 
                         wheel_height/2 + wheel_clearance,
                         tip_radius,
                         1 + wheel_clearance,
                         abutment_radius,
                         bearing_width/2,
                         bolt_sleeve_radius);
        }
        translate([0,0,plate_thickness])
            block_bosses(centers, 
                         wheel_height/2 + wheel_clearance,
                         tip_radius,
                         1 + wheel_clearance,
                         abutment_radius,
                         bearing_width/2,
                         bolt_sleeve_radius);
    }
    union() {
        translate([0,0,-0.01]) cylinder(h=bolt_length,r=bolt_diameter/2,center=false);
        translate([centers,0,-0.01]) cylinder(h=bolt_length,r=bolt_diameter/2,center=false);
        translate([-centers,0,-0.01])cylinder(h=bolt_length,r=bolt_diameter/2,center=false);
    }
}
}



// calculate wheel height ensuring there are always guides at least 2.5mm either side of cable
// bearing_height = bearing[4]
function calc_wheel_height(bearing, cable_diameter) = max(bearing[4], (cable_diameter + 3)) + 2;

// pulley wheel
module wheel(bearing, groove_diameter) {
    difference() {
        bearing_shoulder = bearing[1];
        bearing_recess = bearing[2];
        bearing_outer = bearing[3];
        bearing_width = bearing[4];
        bearing_gap = bearing[2] - bearing[1];// gap between bearing recess and shoulder

        height = calc_wheel_height(bearing, groove_diameter);
        //height = max(bearing_width, (groove_diameter+3)) + 2; // always have guides 2.5mm either side of groove
        extra_radius=2;//space between the bearing and base of groove
        groove_radius = ((bearing_outer + groove_diameter)/2) + extra_radius;
        side_height = (height - groove_diameter)/2;

        union() {
            //main disc
            cylinder(h=height,r=groove_radius+(groove_diameter/2), center=false);
            //grove sides
            translate([0,0,side_height/2]) torus(groove_radius+groove_diameter/2, side_height/2);
            translate([0,0,height - (side_height/2)]) torus(groove_radius+groove_diameter/2, side_height/2);
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


// pulley components in a print plate
module plate(bearing, pulley_count) {
    bolt = BoltData(bolt_size == 0 ? bearing[0]:bolt_size);
    echo(bearing=bearing, bolt=bolt);
    bearing_bore = bearing[0];
    bearing_shoulder = bearing[1];
    bearing_recess = bearing[2];
    bearing_outer = bearing[3];
    bearing_width = bearing[4];

    wheel_height = calc_wheel_height(bearing, cable_diameter);
    wheel_radius = (bearing_outer/2) + 2 + cable_diameter + (wheel_height - cable_diameter)/4 ;
    
    bolt_length_min = bolt[3] + plate_thickness + (pulley_count * (wheel_height + wheel_clearance + wheel_clearance + plate_thickness));
    bolt_length = _select_bolt_len(bolt_length_min, bolt[1]);
    echo(bolt_length_min = bolt_length_min, bolt_length=bolt_length);
    
    // pulley wheel
    for (i=[1:pulley_count]) 
        translate([(i-1) * (wheel_radius + 2) * 2, 0 ,0])
            wheel(bearing, cable_diameter);
    
    
    for (i=[0:pulley_count]) 
        translate([(i * (wheel_radius + 2) * 2)-wheel_radius, -wheel_radius*3, 0]) {
            rotate([0,0,90])
                    blockouter(
                        bearing,
                        bolt,
                        cable_diameter,
                        wheel_radius,
                        wheel_height,
                        bolt_length,
                        ((i == 0)||(i==pulley_count))
                    );
    }    
}

plate(BearingData(bearing_code),1);

