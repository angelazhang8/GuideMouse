# Guide Mouse
![mouse](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/github-images.jpg)
Guide Mouse allows for the tactile exploration of 3D objects digitally. The program inputs a 3D model while displaying its 2D projection on the screen. Users move the tactile mouse around like a regular computer mouse, which changes the cursor position on the screen. Applicator (the main program running Guide Mouse) identifies the facet of the 3D polyhedron mesh the cursor hovers over on the screen, and it outputs three numerical values to the Arduino board to position a feedback plane by driving three motors that are attached to Guide Mouse.

## Report & Posters

#### The Applicate Interpolator for a Facet of a 3D Polygon Mesh Given the Abscissa and Ordinate Program

[Applicolator Report](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/applicolatorReport.pdf)

### Poster

[Guide Mouse Poster](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/poster.pdf)

## Build Process

### Inspiration 
I was inspired to create Guide Mouse after trying out the Phantom Omni at SHAD Western '17. 
Computers have auditory feedback (speakers) and visual feedback (screen) but no tactile feedback. Touch feedback is a large component of our day-to-day lives, yet a nonexistment form of interaction with our desktop computers. I wanted to build this project because Guide Mouse is a product I would like to use.

### Ideation
Going into this project, I had no idea what Guide Mouse was going to look like. So I made rough sketches and then migrated to making paper and foam models to flesh out my idea.

![mouse-models](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/mouse-models.jpg)

### Applicolator
To obtain the normal vector for each facet plane of the polyhedron mesh, I calculated the cross product of two vectors making up the facet plane.
![cross-product](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/cross-product.jpg)
### CAD Modelling
After Guide Mouse had become a skeleton of an idea, I proceded to make CAD models for the parts I needed to 3D-print. Ball/socket model [not pictured] was mixed in Blender from Ball/Joint in Thingiverse.

![AutoCAD1](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/AutoCAD1.jpg)
![AutoCAD3](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/AutoCAD3.jpg)
![AutoCAD2](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/AutoCAD2.jpg)
### 3D-Printing
My high school had the Cubicon 3D printer which I used to print my parts.

![CubiconCubicreator1](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/CubiconCubicreator1.jpg)
![CubiconCubicreator2](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/CubiconCubicreator2.jpg)

### Soldering (16 hours)
My impromptu work station in the basement; my setup was a ping pong table covered with a picnic blanket. I soldered a computer connector from the motor chip to the motors so that the motors have longer connecting wires and can be easily separated from the motor chip.

![solder1](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/solder1.jpg)
![solder2](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/solder2.jpg)

Wires were stripped, twisted, soldered, and taped. Soldering iron, fan, pliers/cutters were generously lent by Mr. Webb.

### Putting it together
After months of work, it's finally time to fit all the pieces together!

![mouse-motors](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/mouse-motors.jpg)
![mouse-underside](https://github.com/xxxzhangxxx/GuideMouse/blob/master/reports/mouse-underside.jpg)

