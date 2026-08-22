# Rasterization
Rasterization is the process of converting vector graphics, defined by coordinates in space, into pixel graphics. For QuickSilver specifically, this means turning triangles with with per-vertex positions, colors and texture coordinates into colored pixels ready for display.

## Process
Unlike most software renderers, we *don't* compute the scanline interpolant at every scanline. This could be more accurate, true, but will also cost us an additional division for every scanline. Instead, we pre-compute the scanline interpolant per-triangle.

Note: remember that the scanlines in MCH3D are *vertical*!

### Linear interpolation
Let's start with the basic case of linear interpolation over a line:

Basic linear interpolation computes values in between two values. Say you have a value *A* and a value *B*, you can interpolate between them by taking a ratio from 0 to 1 (let's call it *t*) and applying them to the two values:

*v = (1 - t) * A + t * B*

So, for t=0 you get 100% the value of A and 0% the value of B, for t=1 you get 0% A and 100% B, and for t=0.2 you get a blend with 80% A and 20% B.

Now, in many cases you don't know this value of *t* directly. Instead, A and B will be points with some position *x* and a value *c*, and the question is what is the value at some arbitrary position between A and B? First we compute the value of *t*:

*t = (x - A.x) / (B.x - A.x)*

Sidenote: This actually the inverse of the linear interpolation formula:
*t = (x - A.x) / (B.x - A.x)*
*t * (B.x - A.x) = x - A.x*
*t * (B.x - A.x) + A.x = x*
*t * B.x - t * A.x + A.x = x*
*t * B.x + (1 - t) * A.x = x*

We then plug that *t* into the linear interpolation over *c*:

*c = (1 - t) * A.c + t * B.c*
*c = (1 - (x - A.x) / (B.x - A.x)) * A.c + (x - A.x) / (B.x - A.x) * B.c*
*c = A.c - A.c*(x - A.x) / (B.x - A.x) + B.c * (x - A.x) / (B.x - A.x)*
*c = A.c + (B.c - A.c) * (x - A.x) / (B.x - A.x)*

This applies to all attributes of A and B that we can interpolate linearly, including the position itself:

*y = A.y + (B.y - A.y) * (x - A.x) / (B.x - A.x)*

Note that the scaling factor *(x - A.x) / (B.x - A.x)* never changes, regardless of the parameter we interpolate.

### Stepwise interpolation
For MCH3D we'll be performing stepwise interpolation, meaning we'll start at the position and value of A, and then step by one pixel and determine the value there, repeating until we've reached B. In other words, iteratively add the *slope* of *c* over *x*. Let's rewrite the formula a bit to make it clearer:

*c = A.c + (B.c - A.c) * (x - A.x) / (B.x - A.x)*
*c = A.c + (B.c - A.c) / (B.x - A.x) * (x - A.x)*
*c = (B.c - A.c) / (B.x - A.x) * x - (B.c - A.c) / (B.x - A.x) * A.x + A.c*

This make is clear that we have a simple linear function with a constant part *-(B.c - A.c) / (B.x - A.x) * A.x + A.c* and a gradient part *(B.c - A.c) / (B.x - A.x) * x*. So computing *(B.c - A.c) / (B.x - A.x)* gives us the change we need to apply when increasing *x* by one, a.k.a. our *interpolant* for *c*.

Note: The constant part *-(B.c - A.c) / (B.x - A.x) * A.x + A.c* may seem complex, but we don't actually need it. This computes the value of *c* for *x=0*, but we don't start our drawing there. We start at *x=A.x*, which of course simply resolves to *c=A.c*.

We can compute these interpolants for each attribute we wish to interpolate. In MCH3D, interpolants over *x* are prefixed with *m*:

*mz = (B.z - A.z) / (B.x - A.x)*
*mr = (B.r - A.r) / (B.x - A.x)*
*mg = (B.g - A.g) / (B.x - A.x)*
*mb = (B.b - A.b) / (B.x - A.x)*
*mu = (B.u - A.u) / (B.x - A.x)*
*mv = (B.v - A.v) / (B.x - A.x)*

### Scanline rasterization
We can apply our stepwise linear interpolants to the edges of our triangle to get any value along those edges. But what about the surface of the triangle? In scanline rasterization, you interpolate along the edges in one direction (horizontally in the case of MCH3D) and then draw a line between the edges in the scanline direction (vertically for MCH3D) to render one scanline of the triangle. Any line passing through a triangle always intersects with exactly two edges, or it passes through a vertex (in which case the two edges meet and we can work with either.) The scanline rasterizer needs to keep track of which edges to interpolate. A more general polygon rasterizer will require an edge list, but the triangle case is a lot simpler:

Any set of three vertices, forming a triangle, can be sorted from left to right (we'll discuss the situations of vertices with equal x-coordinates in a bit) giving us a left-most (v1), middle (v2) and right-most (v3) vertex. We can then identify the edge from v1 to v2 as the left edge, the edge from v2 to v3 as the right edge, and the edge from v1 to v3 as the wide edge (as it spans the widest along the x-axis.) Because our scanlines are always oriented vertically, we know that the scanline will always intersect the wide edge on one side, and on the other side will first intersect with the left edge until it reaches v2, after which it intersects with the right edge (when scanning from left to right.) 

To keep track of the three edges with stepwise interpolation, we will need the following constants:
- The x-coordinate of v1 (x1) to know the first scanline to draw,
- The x-coordinate of v3 (x3) to know the last scanline to draw,
- The x-coordinate of v2 (x2) to know at which scanline to switch from tracking the left edge to tracking the right edge.
- The y-coordinate of v1 (y1) as the initial position of the wide and left edges.
- The y-coordinate of v2 (y2) as the initial position of right edge (technically optional, but greatly improves precision.)
- The interpolant along the wide edge (*m1 = (y3 - y1) / (x3 - x1)*).
- The interpolant along the left edge (*m2 = (y2 - y1) / (x2 - x1)*).
- The interpolant along the right edge (*m3 = (y3 - y2) / (x3 - x2)*).

And the following variables:
- The current scanline (x_curr).
- The current y-coordinate along the wide edge (y_start).
- The current y-coordinate along the other edge (y_end).

With this system, incrementing y_start by m1 for every step of the scanline, and incrementing y_end by m2 (if x_curr < x2) or by m3 (if x_curr > x2), we can trace the outline of the triangle. Drawing a line between y_start and y_end at every scanline will fill the triangle.

In the case where two vertices sit at the same x-coordinate, and thus forms a vertical edge, we can skip either the left or right phases of the interpolation. In the case of a vertical edge on the right side, interpolation happens as described above, but terminates at x2 (as x2=x3) so the right phase is skipped. In the case of a vertical edge on the left side, y_end is initialized with y2 instead of y1, skipping the left phase.

Sidenote: By setting y_start and y_end explicitly, we can actually (ab)use this system to draw trapezoids and pentagons with two vertical edges. Like the triangle, initialize y_start and y_end to different positions to form a vertical edge on the left. By *not* letting m1 and m3 converge at x3 you create a vertical edge on the right. Placing x2 at x1 or x3 creates a trapezoid, placing x2 at another location creates a pentagon.

To know with *what* to fill the triangle, we additionally need the interpolated values of the RGB color components and UV texture coordinates. We could trace the edges using the same method as we did the y-coordinate, with an interpolant per component/per edge, and then interpolate again across the scanline. But this will require many calculations to be done at every scanline. MCH3D does something simpler.

### Surface interpolation
An important realization is that any three non-overlapping point in 3D space *always* make a flat triangle. You cannot "bend" a triangle without adding an additional corner somewhere. This may seem somewhat obvious, but this is not true for quadrilaterals. We can extend the surface of a triangle to an infinite plane and say that those three points describe that particular plane.

Now, if we take that same triangle and swap out the z-coordinate for a different attribute, for example the red component of the vertex colors, we still end up with a flat plane, just in XYR-space instead of XYZ-space. We can use that fact to describe the changes over the surface of the triangle for any of the attributes in a different way. As long as we know one point on the plane as well as the gradient along two non-parallel vectors in XY we've uniquely described the plane. All-in-all, this is a very roundabout way of saying that the gradient along the scanline direction remains constant over the entire triangle for all attributes, and so we can compute this once per triangle, instead of once per scanline.

So we need to find a vertical span over which to calculate the gradient. Any triangle always spans the widest along the scanline at x2, so that's where we should get the highest precision. The attributes at v2 are known, but we'll need to calculate the attributes at x2 along the wide edge to get both sides of the span. Let's call this point v4. In the formula below, *c* is a placeholder for any of the attributes (i.e. depth coordinate z, color components r, g and b, and texture coordinates u and v), *m* is a prefix used for interpolants along the wide edge and *n* is a prefix used for interpolants along the scanline. 

*x4 = x2*
*y4 = (y3 - y1) / (x3 - x1) * (x2 - x1) + y1*
*c4 = (c3 - c1) / (x3 - x1) * (x2 - x1) + c1*
*nc = (c2 - c4) / (y2 - y4)*

Both *y4* and *c4* contain the sub-expression *(x2 - x1) / (x3 - x1)* which we can extract as *Q*, giving us:

*Q = (x2 - x1) / (x3 - x1)*
*y4 = (y3 - y1) * Q + y1*
*c4 = (c3 - c1) * Q + c1*
*nc = (c2 - c4) / (y2 - y4)*