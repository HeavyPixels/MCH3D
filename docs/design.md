# The Plan

The tile-based rendering approach was designed based on the following assumptions and constraints:

- The LCD has an internal framebuffer and allows for very flexible addressing including row scanning, column scanning, windowed access and random access. Full random access is too slow to achieve reasonable framerates, however, so some form of internal buffering in the FPGA is required. Full random access would also make a Z-buffer prohibitively large.
- The only interface between the ESP32 and the FPGA is a 23MHz SPI. At less than 3MB/s this is quite the bottleneck, so care must be taken to minimize the datastream between CPU and FPGA.
- Visible triangles are much more likely to be square-ish than thin horizontal or vertical lines, so any triangle is expected to cover fewer square tiles than it would line buffers making tiling a more efficient binning strategy.
- Texture caching also benefits from square tiles vs line bins as it greatly improves the spatial locality of texel accesses.

Based on all this, a tile-based rendering approach was chosen with 32x32 pixel tiles (the biggest that could reasonably be supported with the FPGA's EBRAM). The CPU would clip and bin triangles per tile and send each bin of triangles to the FPGA. The FPGA will precaclulate the edge gradients and render each triangle in order to the tile buffer. Once all triangles are rendered, the active tile buffer is swapped with the display tile buffer to be transferred to the display.

# Reality

In practice, this plan didn't work out perfectly. The main issue is that the clipping of every triangle for every tile is simply too expensive on the CPU side. Alternatives could be barycentric rendering (which wouldn't require clipping or clipping on the FPGA, but both would require additional digital logic while size was already a major concern.

Size contraints also meant texturing was scrapped for the initial version, negating the texture caching benefits. Finally, the Badge.team managed to up the link speed between CPU and FPGA to 80MHz, giving up to 10MB/s throughput and greatly improving on that bottleneck.

# New Plan

To eliminate the expensive clipping operations, the GPU will be redesigned to a scanline-based renderer, similar to the original QuickSilver. QuickSilver only requires a single view-frustrum clip and an inexpensive binning by top Y-coord.

## Changes

Starting from the back:

- The display controller will be simplified: simple row-major scanning instead of tiles and no arbitrary ordering, only top-to-bottom.
- The display buffers will be converted from 32x32 tiles to (one or more) scanlines.
- Drawline and Calcline will remain mostly identical, save for the hopeful reintroduction of texture coordinates.
- A memory interfacce will be needed if I'm going to store textures in the external PSRAM.
- A triangle FIFO will be required to store any triangles in progress.
- PreCalc is frankly much cheaper than the clipping I tried to do on the CPU before, and accounts for nearly half of the logic area on the FPGA, so it will be moved to the CPU. Directly sending triangles in the precalc format will also allow certain types of quadrilaterals to be supported.
- The command decoder will be quite different, as now it only really needs triangles and texture upload. Some way to communicate buffer overflow back to the CPU would be nice, though.

The "immediacy" of texturing is TBD. In the original tile-based design any UV coordinate would be immediately used to look up a texel and only fully shaded pixels were ever stored in the display buffers. QuickSilver, on the other hand, uses a deferred approach where UV coordinates would first be stored in an intermediate scanline buffer before looking up the texture values only for the visible pixels. The deferred method requires fewer texture lookups (eliminating overdraw) but only the immediate method can support true alpha blending.

The triangle FIFO is by far the largest internal memory block in QuickSilver. Using the precalculated triangle size specified for QuickSilver, we will need at least 465 bits per triangle and a buffer size of at least 128 triangles as this ultimately limits the number of active triangles per scanline. Three types of memory are available on the MCH badge:

- 30x 4kbit EBRAM, of which we would need at least half to store all the triangles, but does have sufficient bandwidth for 2 cycle access;
- 4x 256kbit SPRAM, of which only a single unit is needed for storage, but bandwidth is a major concern with at least 8+8 (R+W) cycles needed when all units are used in parallel;
- 1x 64Mbit PSRAM, which could store multiple *frames* worth of triangles if needed, would need a massive 52 cycles of the main 36MHz clock to just load a single triangle.

As the EBRAM is also needed for other buffers the SPRAM is basically the only viable option for the triangle FIFO. Some logic will need to be created to adapted the three data streams (input from CPU, read to Calcline, and return from Calcline) to the (up to) four 16-bit single-port RAMs. At 60fps, each line consists of exactly 2500 cycles at 36MHz, or up to 156 triangles in pure FIFO I/O. So a 128/line design limit is fine.

