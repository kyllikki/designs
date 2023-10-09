// block and tackle using bearings
//
// Copyright Vincent Sanders 2023 <vince@kyllikki.org>
// Attribution 4.0 International (CC BY 4.0)
// Version 1.2

/* [General] */

// Number of sheaves in the blocks
block_type = "single"; // [single,double,triple,quadruple,quintuple]

// diameter of cable/rope being used
cable_diameter = 4;// [2:12]

// if the cheeks (outer face plates) are thicker to allow bolt heads to be recessed into them
recess_bolts = false;

// show assembly view instead of print plate
show_assembly = false;


/* [Sheaves] */

// code for bearing in sheaves
bearing_code = 608;// [625,608,609,6000,6001,6002,6003,6004,6902]

// if the bearing should be printed
printed_bearing = false;

// axle bolt size (nominal diameter) (bearing - use bearing bore)
axle_size = "bearing"; // [bearing,5,8,10,12,16,20]

// whether the sheaves in the block have side guards
has_sheave_guards = false;


/* [Standing block] */

// Crown load bolt size (nominal diameter) (axle - use axle size)
standing_crown_bolt = "axle"; // [axle,5,8,10,12,16,20]

// Crown attachment type
standing_crown_attachment = "cable"; // [plain,cable]

// Tail load bolt size (nominal diameter) (none - no tail) (same - use crown size)
standing_tail_bolt = "same"; // [none,same,5,8,10,12,16,20]

// Tail attachment type (same - use crown attachment)
standing_tail_attachment = "same"; // [same,plain,cable]


/* [Running block] */

// Crown load bolt size (nominal diameter) (none - no running block) (axle - use axle size)
running_crown_bolt = "axle"; // [none,axle,5,8,10,12,16,20]

// Crown attachment type
running_crown_attachment = "cable"; // [plain,cable]

// Tail load bolt size (nominal diameter) (none - no tail) (same - use crown size)
running_tail_bolt = "none"; // [none,same,5,8,10,12,16,20]

// Tail attachment type (same - use crown attachment)
running_tail_attachment = "same"; // [same,plain,cable]


module __Customizer_Limit__ () {}

wheel_clearance = 0.6;// clerance between wheel and block
wheel_additional_diameter = 4; // material between the bearing and the base of the cable groove
plate_thickness = 2.2;// thickness of plate walls
block_guard_size = 2;
bolt_clearance_idx =1;//index of bolthole clearance to use - none,close,medium,free
printed_bearing_clearance = 0.4;//printed bearing hub clearance (for me 0.3 is solid and 0.4 is sloppy)
rough_preview = true; // if the preview is rough

// openscad detail settings

$fs = ($preview && rough_preview)?1.4:0.1; // minimum fragment size
$fa = ($preview && rough_preview)?5:2; // minimum angle

// name to number map
name_count_map = [["single",1],["double",2],["triple",3],["quadruple",4],["quintuple",5]];

// data for bearings
// [code, [bore, shoulder, recess, outer, width]]
bearing_data = [
    [608,  [8,  12.5,  19.2, 22,  7]],
    [609,  [9, 14.45,  21.2, 24,  7]],
    [625,  [5,   8.4, 13.22, 16,  5]],
    [6000, [10, 14.8,  22.6, 26,  8]],
    [6001, [12,   17, 24.72, 28,  8]],
    [6002, [15, 20.5,  28.2, 32,  9]],
    [6003, [17,   23,  31.2, 35,  10]],
    [6004, [20, 27.2, 37.19, 42, 12]],
    [6902, [15,   17,    26, 28,  7]]
];

// prefered bolt lengths
m5_bolt_lengths= [22,25,30,35,40,45,50,55,60,65];
m8_bolt_lengths= [22,25,30,35,40,45,50,55,60,65,70,75,80];
m10_bolt_lengths=[   25,30,35,40,   50,   60,   70,   80,   90,100];
m12_bolt_lengths=[   25,30,35,40,   50,55,60,65,70,75,80,85,90,100,110];
m16_bolt_lengths=[      30,35,40,   50,55,60,65,70,75,80,   90,100,110];
m20_bolt_lengths=[      30,35,40,   50,55,60,65,70,75,80,   90,100,110];

// nut and bolt sizes used for axle and support shafts
// data set is for DIN standard hardware
// nominal diameter, [diameter, [lengths], nut flats, nut height, nut corners, [clearence diameters none,close,medium,free]]
bolt_data = [
[5,  [ 5,  m5_bolt_lengths,  8,  5,  9.2, [0, 0.3, 0.5, 0.8]]],
[8,  [ 8,  m8_bolt_lengths, 13,  8,   15, [0, 0.4,   1,   2]]],
[10, [10, m10_bolt_lengths, 17, 10, 19.6, [0, 0.5,   1,   2]]],
[12, [12, m12_bolt_lengths, 19, 12, 22.1, [0,   1,   2,   3]]],
[16, [16, m16_bolt_lengths, 24, 16, 27.7, [0,   1,   2,   3]]],
[20, [20, m20_bolt_lengths, 30, 20, 34.6, [0,   1,   2,   4]]],
];

// get number from number of pulleys descriptive name
function NameToNumber(name) = [for (x = name_count_map) if (x[0] == name) x[1]][0];

// get bearing data
function BearingData(code) = _table_search(bearing_data, code, 608);

// get bolt data
function BoltData(bore) = _table_search(bolt_data, bore, 5);

bearingbore_bolt_map = [[5, 5], [8, 8], [9, 8], [10, 10], [12, 12], [15, 12], [16, 16], [17, 16], [20, 20]];
// get bolt data from bearing bore to available bolt sizes
function MappedBoltData(bore) = BoltData(_table_search(bearingbore_bolt_map, bore, 5));

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

module bearing_print(bearing) {
    bearing_bore = bearing[0];
    bearing_shoulder = bearing[1];
    bearing_recess = bearing[2];
    bearing_outer = bearing[3];
    bearing_width = bearing[4];

    // gap radius is halfway between the abutment radius and the outer bearing radius
    gap_radius = (bearing_outer/4) + (bearing_recess/12) + (bearing_shoulder/6);
    gap_unit = bearing_width / 12;
    gap_size = printed_bearing_clearance/2;

    difference() {
        cylinder(h=bearing_width, r=bearing_outer/2+0.01,center=false);
        union() {
        //bearing bore
        translate([0,0,-0.1]) cylinder(h=bearing_width+0.2,r=bearing_bore/2, center=false);
        rotate_extrude(convexity = 5)
            translate([gap_radius,0,0])
            polygon([
                    [-gap_size, -0.1],
                    [-gap_size - 3*gap_unit, 4*gap_unit],
                    [-gap_size - 3*gap_unit, 8*gap_unit],
                    [-gap_size, 0.1+(12*gap_unit)],
                    [gap_size, 0.1+(12*gap_unit)],
                    [gap_size - 3*gap_unit, 8*gap_unit],
                    [gap_size - 3*gap_unit, 4*gap_unit],
                    [gap_size, -0.1],
                    [-gap_size, -0.1]
                  ]);
        }
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
function calc_sheave_height(bearing, cable_diameter) = max((bearing[4] + 2), (cable_diameter + 5));

// the diameter of the wheel side guides
function calc_wheel_guide_diameter(bearing, cable_diameter) =
    (calc_sheave_height(bearing, cable_diameter) - cable_diameter) / 2;

// calculate wheel radius
// bearing_outer = bearing[3];
// bearing radius + extra bearing diameter + cable radius + guide side radius
// TODO : cable radius vs cable diameter, i think the side guides are a cable radius too tall?
function calc_sheave_radius(bearing, cable_diameter) =
    (bearing[3] +
     wheel_additional_diameter +
     calc_wheel_guide_diameter(bearing, cable_diameter)
    ) / 2 + cable_diameter;

// compute the distance between the axle and support shaft centers
function calc_support_length(wheel_radius, bolt, attachment) =
    let(bolt_radius = bolt[0]/2,
        bolt_flat_radius = bolt[2]/2,
        cable_guide_size = cable_diameter - (attachment == "cable" ? (bolt_flat_radius - bolt_radius - 2):0)
       ) wheel_radius + wheel_clearance + bolt_flat_radius + cable_guide_size;

// calculate the radius of the end of the support
// currently just the size of the bolt flats
function calc_support_radius(bolt) = bolt[2]/2;

// calculate center axle disc radius
function calc_center_radius(wheel_radius) = wheel_radius + wheel_clearance + (has_sheave_guards? block_guard_size: 0);

// support with cable guide hole
//bearing_shoulder_diameter = bearing[1]
module gen_support_cable_guide(wheel_radius, boss_height, bearing, bolt, thickness, outer) {
    center = calc_support_length(wheel_radius, bolt, "cable");
    bolt_radius = bolt[0]/2;
    bolt_flat_radius = bolt[2]/2;
    cable_guide_radius = max((bearing[1]) / 2, bolt_flat_radius + cable_diameter/2 );
    cable_guide_center=center + cable_guide_radius - cable_diameter/2 - bolt_radius - 1;

    difference() {
        union()  {
            // boss at tip of the plate around bolt
            translate([center,0,0])
                cylinder(h=(outer ? 0 : boss_height) + thickness + boss_height,
                     r=bolt_flat_radius,
                     center=false);

            intersection() {
                translate([cable_guide_center,0,0])
                    cylinder(h=(outer ? 0 : boss_height) + thickness + boss_height,
                             r=cable_guide_radius + cable_diameter/2+1,
                             center=false);

                tangent_join(calc_center_radius(wheel_radius),
                             bolt_flat_radius,
                             center,
                             thickness + 2 * boss_height);
            }
        }

        translate([cable_guide_center,0,(outer ? 0 : boss_height)+thickness + boss_height])
            torus(cable_guide_radius, cable_diameter/2);
        if (!outer) translate([cable_guide_center,0,0])
            torus(cable_guide_radius, cable_diameter/2);

    }
}

// support with just plain cover over bolt
module gen_support_no_guide(wheel_radius, boss_height, bolt, thickness, outer) {
    bolt_flat_radius = bolt[2]/2;
    center = calc_support_length(wheel_radius, bolt, "plain");

    // boss at tip of the plate around bolt
    translate([center,0,0])
        cylinder(h=(outer ? 0 : boss_height) + thickness + boss_height,
                 r=bolt_flat_radius,
                 center=false);
}



// support on one side of the axle
module support(wheel_radius, wheel_height, bearing, bolt, attachment, thickness, bolt_length, outer) {
    boss_height = wheel_height / 2 + wheel_clearance;
    // different structures for cable handling
    if (attachment=="cable") {
        gen_support_cable_guide(wheel_radius, boss_height, bearing, bolt, thickness, outer);
    } else {
        gen_support_no_guide(wheel_radius, boss_height, bolt, thickness, outer);
    }
}

// guard sides
module sheave_guards(radius, height,cut_angle=45) {
    difference() {
        cylinder(h=height, r=radius, center=false);
        translate([0, 0, -0.01])
            union() {
                cylinder(h=height + 0.02, r=radius - block_guard_size, center=false);
                rotate([0, 0,-(cut_angle/2)]) cube([radius, radius,height+0.02], center=false);
                rotate([0, 0,90+(cut_angle/2)]) cube([radius, radius,height+0.02], center=false);
                rotate([0, 0,-90+(cut_angle/2)]) cube([radius, radius,height+0.02], center=false);
                rotate([0, 0,180-(cut_angle/2)]) cube([radius, radius,height+0.02], center=false);
            }
    }
}


// support plate side guards, bearing abutments and bearing sleeve
module center(wheel_radius, wheel_height, bearing, axle, thickness, bolt_length, outer) {
    bearing_bore = bearing[0];
    bearing_shoulder = bearing[1];
    bearing_recess = bearing[2];
    bearing_width = bearing[4];

    // bearing shoulder abutment is 1/3rd of the space between bearing shoulder and recess
    abutment_radius = (bearing_recess/6) + (bearing_shoulder/3);
    abutment_height = ((wheel_height - bearing_width)/2)+wheel_clearance;

    bolt_sleeve_radius = (axle[0] < bearing_bore ? bearing_bore/2 : 0);
    bolt_sleeve_height= bearing_width/2;
    bolt_radius = axle[0]/2;
    boss_height = wheel_height/2 + wheel_clearance;

    translate([0,0,outer ? 0 : boss_height]) {
        //%translate([0,0,plate_thickness+wheel_clearance]) wheel(bearing, cable_diameter);

        // block guards
        if (has_sheave_guards)
            translate([0,0,outer?0:-boss_height])
                sheave_guards(calc_center_radius(wheel_radius),
                             (outer?0:boss_height) + thickness + boss_height,
                             45);

        // center abutment
        translate([0,0,outer?0:-abutment_height])
            cylinder(h=(outer?0:abutment_height) + thickness + abutment_height,
                     r=abutment_radius,
                     center=false);

        // make bearing fit on bolt with sleeve if required
        if (bolt_sleeve_radius > 0)
            translate([0,0,outer?0:-boss_height])
                cylinder(h=(outer?0:boss_height) + thickness + boss_height,
                         r=bolt_sleeve_radius,
                         center=false);
     }
}

// block face plate
// shafts = [axle, support1, support2]
module blockfacemain(wheel_radius, wheel_height, shafts, attachments, thickness, outer) {
    center_radius = calc_center_radius(wheel_radius);
    boss_height = (wheel_height / 2) + wheel_clearance;

    translate([0,0,outer ? 0 : boss_height])
    union() {
        // center disc
        cylinder(h=thickness, r=center_radius, center=false);
        // tangent section1
        if (!is_undef(shafts[1]))
            tangent_join(center_radius,
                     calc_support_radius(shafts[1]),
                     calc_support_length(wheel_radius, shafts[1], attachments[0]),
                     thickness);
        // tangent section2
        if (!is_undef(shafts[2]))
            rotate([0,0,180])
                tangent_join(center_radius,
                             calc_support_radius(shafts[2]),
                             calc_support_length(wheel_radius, shafts[2], attachments[1]),
                             thickness);
    }
}

// bolt holes
// shafts = [axle, support1, support2]
module blockboltholes(wheel_radius, shafts, attachments, bolt_length) {

    //axle
    translate([0, 0, -0.01])
        cylinder(h=bolt_length, r=(shafts[0][0] + shafts[0][5][bolt_clearance_idx]) / 2, center=false);
    //support 1
    if (!is_undef(shafts[1]))
        translate([calc_support_length(wheel_radius, shafts[1], attachments[0]), 0, -0.01])
        cylinder(h=bolt_length, r=(shafts[1][0] + shafts[1][5][bolt_clearance_idx]) / 2, center=false);
    //support 2
    if (!is_undef(shafts[2]))
        translate([-calc_support_length(wheel_radius, shafts[2], attachments[1]), 0, -0.01])
            cylinder(h=bolt_length, r=(shafts[2][0] + shafts[2][5][bolt_clearance_idx]) / 2, center=false);
}

module blockboltheads(wheel_radius, shafts, attachments, isnut) {
    nut_height = calc_nut_height(shafts);
    //axle
    translate([0, 0, -0.01])
        cylinder(h=nut_height, r=(shafts[0][4] + shafts[0][5][bolt_clearance_idx]) / 2, center=false, $fn=isnut?6:0);
    //support 1
    if (!is_undef(shafts[1]))
        translate([calc_support_length(wheel_radius, shafts[1], attachments[0]), 0, -0.01])
        cylinder(h=nut_height, r=(shafts[1][4] + shafts[1][5][bolt_clearance_idx]) / 2, center=false, $fn=isnut?6:0);
    //support 2
    if (!is_undef(shafts[2]))
        translate([-calc_support_length(wheel_radius, shafts[2], attachments[1]), 0, -0.01])
            cylinder(h=nut_height, r=(shafts[2][4] + shafts[2][5][bolt_clearance_idx]) / 2, center=false, $fn=isnut?6:0);
}

function calc_nut_height(shafts) =
    max(shafts[0][3],
        (is_undef(shafts[1]) ? 0 : shafts[1][3]),
        (is_undef(shafts[2]) ? 0 : shafts[2][3]));

// calculate the required plate thickness from shaft bolt head sizes and whether this is an outer plate
function calc_plate_thickness(shafts, outer) =
    plate_thickness + (outer ? (recess_bolts ? calc_nut_height(shafts) : 0) : 0);

// generate a face of the block
module blockface(bearing, shafts, attachments, cable_diameter, wheel_radius, bolt_length, outer, first) {
    wheel_height = calc_sheave_height(bearing, cable_diameter);
    thickness = calc_plate_thickness(shafts, outer);

    difference() {
        union() {
            blockfacemain(wheel_radius, wheel_height, shafts, attachments, thickness, outer);

            // center abutments and guards
            center(wheel_radius, wheel_height, bearing, shafts[0],thickness, bolt_length, outer);

            // first support
            if (!is_undef(shafts[1]))
                support(wheel_radius, wheel_height, bearing, shafts[1], attachments[0], thickness, bolt_length, outer);

            // second support
            if (!is_undef(shafts[2]))
                rotate([0,0,180])
                    support(wheel_radius, wheel_height, bearing, shafts[2], attachments[1],thickness, bolt_length, outer);
        }
        if (recess_bolts && outer)
            blockboltheads(wheel_radius, shafts, attachments, !first);
        blockboltholes(wheel_radius, shafts, attachments, bolt_length);
    }
}

// generate a sheave
module sheave(bearing, groove_diameter) {
    bearing_width = bearing[4];
    height = calc_sheave_height(bearing, groove_diameter);

    union() {
        difference() {
            bearing_shoulder = bearing[1];
            bearing_recess = bearing[2];
            bearing_outer = bearing[3];

            // radius of the recess bearing abutment
            abutment_radius = (bearing_recess/3) + (bearing_shoulder/6);

            side_height = (height - groove_diameter) / 2;
            guide_height = calc_wheel_guide_diameter(bearing, groove_diameter);

            groove_radius = ((bearing_outer + wheel_additional_diameter + groove_diameter) / 2);

            union() {
                //main disc
                cylinder(h=height, r=groove_radius + (groove_diameter / 2), center=false);
                //groove sides
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
                    cylinder(h=height+0.2, r=(printed_bearing ? bearing_outer/2 : abutment_radius), center=false);
                // groove
                translate([0,0,height / 2])
                    rotate_extrude(convexity = 10, $fn = 100)
                        translate([groove_radius, 0, 0])
                            union() {
                                circle(r = groove_diameter / 2, $fn = 100);
                                translate([0,-groove_diameter/2,0])
                                    square([groove_diameter*2,groove_diameter], center=false);
                            }
            }
        }

        // bearing
        translate([0,0,(height - bearing_width)/2])
            if (printed_bearing)
                bearing_print(bearing);
            else
                %bearing_placeholder(bearing);
    }
}


function toInt(s, ret=0, i=0) = i >= len(s) ? ret: toInt(s, ret*10 + ord(s[i]) - ord("0"), i+1);

// generate a list if shaft sizes based on configuration
function calc_shafts(bearing) =
    let(axle = MappedBoltData(axle_size == "bearing" ? bearing[0]:min(bearing[0],toInt(axle_size))),
        support1 = (standing_crown_bolt == "axle" ? axle : BoltData(toInt(standing_crown_bolt))),
        support2 = (standing_tail_bolt == "none" ? undef :
                       (standing_tail_bolt == "same" ? support1 :
                           BoltData(toInt(standing_tail_bolt)))),
        support3 = (running_crown_bolt == "none" ? undef :
                       (running_crown_bolt == "axle" ? axle : BoltData(toInt(running_crown_bolt)))),
        support4 = (running_tail_bolt == "none" ? undef :
                       (running_tail_bolt == "same" ? support3 :
                           BoltData(toInt(running_tail_bolt))))
    )
    [axle, support2, support1, support3, support4];

// calculate the attachment types
// standing true if standing block else false
function calc_attachments(standing) = standing?
    [(standing_tail_attachment == "same"? standing_crown_attachment:standing_tail_attachment), standing_crown_attachment]:
    [running_crown_attachment, (running_tail_attachment == "same"? running_crown_attachment:running_tail_attachment)];

// compute a real bolt length from those available
function calc_bolt_length(bolt, bearing, cable_diameter,pulley_count) =
    _select_bolt_len(bolt[3] +
                         plate_thickness +
                         (pulley_count *
                             (calc_sheave_height(bearing, cable_diameter) +
                                 wheel_clearance +
                                 wheel_clearance +
                                 plate_thickness)),
                     bolt[1]);


// pulley components in a print plate
module plate(bearing, pulley_count) {
    echo(bearing=bearing, pulley_count=pulley_count);

    shafts = calc_shafts(bearing);
    echo(len(shafts), shafts=shafts);

    sheave_radius = calc_sheave_radius(bearing, cable_diameter);
    echo(sheave_radius = sheave_radius);

    axle_length = calc_bolt_length(shafts[0], bearing, cable_diameter, pulley_count);
    echo(axle_length = axle_length);

    // sheaves for both blocks
    total_pulley_count = (is_undef(shafts[3]) ? pulley_count: 2 * pulley_count);
    for (i=[1 : total_pulley_count])
        translate([(i-(is_undef(shafts[3]) ? 1:2)) * (sheave_radius + 4) * 2, 0 ,0])
            sheave(bearing, cable_diameter);

    // block sides
    for (blk=[0:(is_undef(shafts[3]) ? 0:1)]) {
        mult = (blk==0?-1:1);
        for (i=[0:pulley_count]) {
            translate([(i * (sheave_radius + 4) * 2) - sheave_radius, mult * sheave_radius * 3, 0])
                rotate([0,0,90*mult*-1])
                    blockface(bearing,
                               [shafts[0], shafts[(blk*2)+1], shafts[(blk*2)+2]],
                               calc_attachments((blk==0)),
                               cable_diameter,
                               sheave_radius,
                               axle_length,
                               ((i == 0)||(i==pulley_count)),
                               (i == 0));
        }
    }
}

function calc_plate_heights(shafts, sheave_height, pulley_count) =
    [for(i=[0:pulley_count])
        calc_plate_thickness(shafts, ((i == 0)||(i==pulley_count))) +
            (((sheave_height/2) + wheel_clearance) * (((i == 0)||(i==pulley_count))? 1:2)) ];

module assembly_block(bearing, shafts, attachments,sheave_radius, pulley_count) {
    sheave_height = calc_sheave_height(bearing, cable_diameter);

    axle_length = calc_bolt_length(shafts[0], bearing, cable_diameter, pulley_count);

    plate_heights = calc_plate_heights(shafts, sheave_height, pulley_count);

    cumsum2 = [ 0,
                for (a=0, b=plate_heights[0];
                     a < len(plate_heights);
                     a = a + 1, b = b + (plate_heights[a] == undef ? 0 : plate_heights[a]))
                b];

    for (i=[0:pulley_count])
        translate([(i==pulley_count)?cumsum2[i]+plate_heights[0]:cumsum2[i],0,0])
            rotate([0,(i==pulley_count)?90:90, (i==pulley_count)?180:0])
                union() {
                    blockface(bearing,
                               shafts,
                               attachments,
                               cable_diameter,
                               sheave_radius,
                               axle_length,
                               ((i == 0)||(i==pulley_count)),
                               (i == 0));
                    if (i < pulley_count)
                        translate([0, 0, plate_heights[i] - (sheave_height / 2)])
                        sheave(bearing, cable_diameter);
                }

    %rotate([0,90,0])  union() {
        translate([0,0,-calc_nut_height(shafts)]) blockboltheads(sheave_radius, shafts,attachments);
        blockboltholes(sheave_radius, shafts, attachments,calc_bolt_length(shafts[0], bearing, cable_diameter, pulley_count));
    }
}

module assembly(bearing, pulley_count) {
    shafts = calc_shafts(bearing);

    sheave_radius = calc_sheave_radius(bearing, cable_diameter);

    // standing block
    translate([0,0,sheave_radius*2.5])
        assembly_block(bearing, [shafts[0], shafts[1], shafts[2]],calc_attachments(true), sheave_radius, pulley_count);
    // running block
    if (!is_undef(shafts[3]))
        translate([0,0,-sheave_radius*2.5])
            assembly_block(bearing, [shafts[0], shafts[3], shafts[4]],calc_attachments(false), sheave_radius, pulley_count);
}

if (show_assembly)
    assembly(BearingData(bearing_code), NameToNumber(block_type));
else
    plate(BearingData(bearing_code), NameToNumber(block_type));
