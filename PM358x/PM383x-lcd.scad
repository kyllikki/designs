// PM8535 LCD screen mount
echo(version=version());

/* [Parts and display] */
// which part to export
part="front"; // [front, back, mounting]
// show facia and screen
show="all"; // [all, parts, none]
// bed width
bed_w = 220;

/* [VDU apature] */
// apature width
apature_w = 180;
// apature height
apature_h = 137;
// apature depth
apature_d = 22;
// amount overlaped behind apature
apature_o = 8;

/* [Mounting points] */
// mounting width
mount_w = 213;
//mounting height
mount_h = 160;
// mounting stud diameter (M4 thread with 7mm nut)
mount_d = 4;
// mounting stud base diameter
mount_base_d = 19;
// mount tab diameter
mount_tab_d = 10;


/* [LCD screen] */
// screen width
screen_w=173;
// screen height
screen_h=136;
// screen depth
screen_d=3;
// additional space between screen and mount
screen_e=1; 

/* [mount face] */
// amount the screen is overlapped by a border
face_o=3; 
// depth to LCD screen 
face_d=1; 

module __Customizer_Limit__ () {}


// calculated values
face_o2 = face_o * 2;
apature_o2 = apature_o * 2;
screen_e2 = screen_e * 2;

// standoff radius
standoff_r = ((apature_w + apature_o2) - (screen_w + screen_e2)) / 4;

// fixing bolts location
bolt_x = ((apature_w + apature_o2) / 2) - standoff_r;
bolt_y = ((apature_h + apature_o2) / 2) - standoff_r;

facia_d = 10; //facia depth
facia_o2 = 20*2; // facia overlap


module cylinder_outer(height,radius,fn) {
   fudge = 1/cos(180/fn);
   cylinder(h=height,r=radius*fudge,$fn=fn);
}
   
module m3_hex_bolt(height) {
    translate([0,0,-0.1]) union() {
        cylinder(h=2.1, r=7/2, $fn=6); // hex head 5mm across flats 2mm high
        translate([0,0,2]) cylinder_outer(height+0.1, 3/2, 12);
    }
}


module bolt_pattern(x,y) {
    translate([ x,  y,    0]) m3_hex_bolt(25);
    translate([ x, -y,    0]) m3_hex_bolt(25);
    translate([ 0,  y, -2.1]) m3_hex_bolt(25);
    translate([ 0, -y, -2.1]) m3_hex_bolt(25);
    translate([-x,  y,    0]) m3_hex_bolt(25);
    translate([-x, -y,    0]) m3_hex_bolt(25);    
}

module prism(l, w, h) {
       polyhedron(
           points=[[0,0,0], [l,0,0], [l,w,0], [0,w,0], [0,w,h], [l,w,h]],
           faces=[[0,1,2,3],[5,4,3,2],[0,4,5,1],[0,3,4],[5,2,1]]
       );
}


module gusset(x, y, height, r, gusset_w) {
    translate([x, y, 0]) rotate([0,0,r]) prism(gusset_w, height, height);
}

module standoff(x, y, height, radius, gusset_w, fn) {
    gusset_l = height;
    translate([x, y, 0]) cylinder(h=height, r = radius, $fn=fn);
    if (x>0) {
        gusset(x-gusset_l-(radius/2), y+(gusset_w/2), height, -90, gusset_w);
    } else {
        gusset(x+gusset_l+(radius/2), y-(gusset_w/2), height, 90, gusset_w);
    }
    if (x==0) {
        // x is corre4ct for centre post gussets
        gusset(x-gusset_l-(radius/2), y+(gusset_w/2), height, -90, gusset_w);
    } else if (y>0) {
        gusset(x-(gusset_w/2), y-gusset_l-(radius/2), height, 0, gusset_w);
    } else {
        gusset(x+(gusset_w/2), y+gusset_l+(radius/2), height, 180, gusset_w);
    }

}

module standoffs(x,y,height, radius, gusset_w, fn) {
    translate([0, 0, 0]) {
        standoff( x,  y,height, radius, gusset_w, fn);
        standoff( x, -y,height, radius, gusset_w, fn);
        standoff( 0,  y,height, radius, gusset_w, fn);
        standoff( 0, -y,height, radius, gusset_w, fn);
        standoff(-x,  y,height, radius, gusset_w, fn);
        standoff(-x, -y,height, radius, gusset_w, fn);
    }
}

module standoff_spacers(x,y,height, radius, fn) {
    translate([x, y, -(height/2)]) cube([radius*2.1,radius*2.1,height],center=true);
    translate([x, -y, -(height/2)]) cube([radius*2.1,radius*2.1,height],center=true);
    translate([-x, y, -(height/2)]) cube([radius*2.1,radius*2.1,height],center=true);
    translate([-x, -y, -(height/2)]) cube([radius*2.1,radius*2.1,height],center=true);
}

module mounting_stud(x, y, height, fn) {
    translate([ x,  y, 0])
        cylinder(h = apature_d - 0.1, r=mount_base_d/2, $fn=fn);
    translate([ x,  y, apature_d-0.1]) 
        cylinder(h = height + 0.1, r=mount_d/2, $fn=fn);
}

module mounting_studs(x,y,height) {
    mounting_stud(x,y, height, 36);
    mounting_stud(-x,y, height, 36);
    mounting_stud(x,-y, height, 36);
    mounting_stud(-x,-y, height, 36);
}

// mounting tab between standoff and mounting stud
// first coordinate is mounting stud, second is standoff
module mounting_tab(x1, y1, tab_r, hole_r, x2, y2, r2, fn) {
    difference() {
        hull() {
          translate([ x1, y1]) circle(r=tab_r, $fn=fn);
          translate([ x2, y2]) circle(r=r2, $fn=fn);
        }
        translate([ x1, y1]) circle(r=hole_r, $fn=fn);
    }
}

module mounting_tabs(x1,y1,tab_r,hole_r, x2,y2,r2, fn) {
    mounting_tab( x1,  y1, tab_r, hole_r,  x2,  y2, r2, fn);
    mounting_tab(-x1,  y1, tab_r, hole_r, -x2,  y2, r2, fn);
    mounting_tab( x1, -y1, tab_r, hole_r,  x2, -y2, r2, fn);
    mounting_tab(-x1, -y1, tab_r, hole_r, -x2, -y2, r2, fn);
}

module ribs(x,y,w,h) {
    translate([ x,  0, h/2]) cube([        w, y * 2 + w, h], center = true);
    translate([-x,  0, h/2]) cube([        w, y * 2 + w, h], center = true);
    translate([ 0,  y, h/2]) cube([x * 2 + w,         w, h], center = true);
    translate([ 0, -y, h/2]) cube([x * 2 + w,         w, h], center = true);
}

module face(h) {
    linear_extrude(height = h)
        difference() {
            square([apature_w + apature_o2, apature_h + apature_o2], center = true);
            square([    screen_w - face_o2, screen_h - face_o2    ], center = true);
        }
}

module front() {
    difference() {
        union() {
            face(face_d);
            // around
            translate([ 0,0,face_d])
            linear_extrude(height = screen_d)
            difference() {
                square([(apature_w + apature_o2), (apature_h + apature_o2)], center = true);
                square([screen_w + screen_e2, screen_h + screen_e2], center=true);    
            }
        }
        // bolt holes
        bolt_pattern(bolt_x, bolt_y);
   }
}

module back() {
    difference() {
        union() {
            face(face_d * 2);
            translate([0,0,face_d*2]) {
                // outer
                ribs(((apature_w + (apature_o2-face_d))/2),
                     ((apature_h + (apature_o2-face_d))/2),
                     face_d,
                     face_d * 2);
                // center
                ribs(bolt_x,
                     bolt_y,
                     face_d,
                     face_d * 2);
                // inner
                ribs(((screen_w - face_o2+ face_d)/2),
                     ((screen_h - face_o2+ face_d)/2),
                     face_d,
                     face_d * 2);
            }
            standoffs(bolt_x,
                      bolt_y,
                      apature_d - (face_d + screen_d),
                      standoff_r,
                      face_d,
                      36);
        }    
        // bolt holes
        translate([ 0,0,-(face_d+screen_d)])
            bolt_pattern(bolt_x, bolt_y);      
   }
}

// mounting bracket attaches assembly to existing mount points
module mounting() {
    inner_w = (apature_w + apature_o2) - (standoff_r * 4);
    inner_h = (apature_h + apature_o2) - (standoff_r * 4);
    
    difference() {
        union() {
            linear_extrude(height = (face_d*2))
            difference() {
                union() {
                    square([(apature_w + apature_o2),
                            (apature_h + apature_o2)],
                           center = true);
                    mounting_tabs(mount_w/2,
                                  mount_h/2,
                                  mount_tab_d/2,
                                  (mount_d+1)/2,
                                  bolt_x,
                                  bolt_y,
                                  standoff_r,
                                  18);
                    
                }
                square([inner_w, inner_h], center=true);
            }
            
            translate([0,0,face_d*2]) { 
                //inner
                ribs(((inner_w + face_d)/2),
                     ((inner_h + face_d)/2),
                     face_d,
                     face_d * 2);
                //outer
                ribs(((apature_w + apature_o2-face_d)/2),
                     ((apature_h + apature_o2-face_d)/2),
                     face_d,
                     face_d * 2);
            }
        }
   
        // bolt holes
        translate([ 0,0,-apature_d])
            bolt_pattern(bolt_x, bolt_y);
        translate([ 0,0,-apature_d])
            mounting_studs((mount_w/2), (mount_h/2), 16);
        // clip to bed width
        translate([ (bed_w + 10) / 2, 0, 0])
            cube([10, 200, 10], center=true);
        translate([-(bed_w + 10) / 2, 0, 0])
            cube([10, 200, 10], center=true);
   }
}

// plots placeholder objects for the screen facia and mounting points
module placeholders() {
    //screen placeholder
    translate([0,0,face_d])
        linear_extrude(height = screen_d)
            square([screen_w,screen_h], center=true);
    //facia placeholder
    translate([0,0,-facia_d])
    linear_extrude(height = facia_d)
    difference() {
        square([(apature_w + facia_o2), (apature_h + facia_o2)], center=true);
        square([apature_w, apature_h], center=true);        
    }
    mounting_studs((mount_w/2), (mount_h/2), 16);
}


if (part=="front") {
    front();
} else {
    if (show=="all" || show=="parts") {
        %front();
    }
}

*    translate([0,0,face_d])
        linear_extrude(height = screen_d)
            square([screen_w,screen_h], center=true);

translate([ 0,0,face_d+screen_d])
if (part=="back") {
    back();
} else {
    if (show=="all" || show=="parts") {
        %back();
    }
}

translate([ 0,0,apature_d])
if (part=="mounting") {
    mounting();
} else {
    if (show=="all" || show=="parts") {
        %mounting();
    }
}

if (show=="all") {
    %placeholders();
}