module rounded_corner(corner_x,corner_y, corner_type)
{
    //rounded corner
  translate([corner_x, corner_y, 0]) { 
    if (corner_type == 0) {
      difference() {
        cube([4,4,1.2], false);
        translate([4,4,0]) {
          cylinder($fn=40, h=1.2, r=4, centre=false);
        }
      }
    } else if (corner_type == 1) {
      difference() {
        translate([-4,0,0]) {
          cube([4,4,1.2], false);
        }
        translate([-4,4,0]) {
          cylinder($fn=40, h=1.2, r=4, centre=false);
        }
      }
    } else if (corner_type == 2) {
      difference() {
        translate([0,-4,0]) {
          cube([4,4,1.2], false);
        }
        translate([4,-4,0]) {
          cylinder($fn=40, h=1.2, r=4, centre=false);
        }
      }
    } else if (corner_type == 3) {
      difference() {
        translate([-4,-4,0]) {
          cube([4,4,1.2], false);
        }
        translate([-4,-4,0]) {
          cylinder($fn=40, h=1.2, r=4, centre=false);
        }
      }
    }
  }
}

module pcb()
{
  color("Green") {
    difference() {
      cube([127,79.5,1.2] , false);
      rounded_corner(0, 0, 0);
      rounded_corner(127, 0, 1);
      rounded_corner(0, 79.5, 2);
      rounded_corner(127, 79.5, 3);

      translate([4.3,4.3,0]) {
        cylinder($fn=20, h=1.2, r=3/2, center=false);
      }
      translate([122.7,4.3,0]) {
        cylinder($fn=20, h=1.2, r=3/2, center=false);
      }
      translate([4.3, 75.2,0]) {
        cylinder($fn=20, h=1.2, r=3/2, center=false);
      }
      translate([122.7,75.2,0]) {
        cylinder($fn=20, h=1.2, r=3/2, center=false);
      }
    }
  }
}

module connectors()
{
  color("red") {
    translate([0,0,1.2]) {
      //micro usb power
      translate([-1.3, 13.7, 0]) {
        cube([6, 8, 3], false);
      }

      //ethernet
      translate([-2.5, 32, 0]) {
        difference() {
          cube([21, 16, 13.4], false);
          union() {
            translate([0, 6, 1]) {
              cube([9, 4, 3], false);
            }
            translate([0, 2, 4]) {
              cube([10, 12, 7], false);
            }
          }
        }
        
      }

      //hdmi
      translate([-2, 53.25, 0]) {
        union() {
          translate([0, 0, 0.7]) {
            cube([2, 15, 5.5], false);
          }
          translate([2, 0, 0]) {
            cube([10, 15, 6.2], false);
          }
        }
      }

      //USB
      translate([113.9, 55.9, 0]) {
        union() {
          cube([13.1, 13.2, 15.6], false);
          translate([13.1, 0, 1.1]) {
            cube([4.3, 13.2, 14.4], false);
          }
        }
      }



      //reset
      translate([123.8, 45.55, 0]) {        
        union() {
          translate([3.2, 7.3/2, 3.1]) {
            rotate([0,90,0]) {
              cylinder($fn=40, h=1, r=3.5/2, center=false);
            }
          }
          cube([3.2, 7.3, 6.2], false);
        }
      }
    
      //power
      translate([123.8, 36.35, 0]) {        
        union() {
          translate([3.2, 7.3/2, 3.1]) {
            rotate([0,90,0]) {
              cylinder($fn=40, h=1, r=3.5/2, center=false);
            }
          }
          cube([3.2, 7.3, 6.2], false);
        }
      }


      //Audio
      translate([115.1, 9.8, 0]) {
        difference() {
          union() {
            translate([11.9, 3.2, 2.05]) {
              rotate([0,90,0]) {
                cylinder($fn=40, h=1.6, r=5/2, center=false);
              }
            }
            cube([11.9, 6.4, 4.1], false);
          }
          translate([0.1,3.2,2.05]) {
            rotate([0,90,0]) {
              cylinder($fn=40, h=13.5, r=3.5/2, center=false);
            }
          }
        }
      }
    

      //micro SD
      translate([96.8, 0, 0]) {
        difference() {
          cube([14.9, 14.9, 1.7], false);
          translate([1, 0, 0.6]) {
            cube([11, 12, 1], false);
          }
        }
      }




    }
  }
}

pcb();
connectors();