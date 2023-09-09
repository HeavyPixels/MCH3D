# The Plan

The tile-based rendering approach was designed based on the following assumptions and constraints:

- The LCD has an internal framebuffer and allows for very flexible addressing including row scanning, column scanning, windowed access and random access. Full random access is too slow to achieve reasonable framerates, however, so some form of internal buffering in the FPGA is required. Full random access would also make a Z-buffer prohibitively large.
- The only interface between the ESP32 and the FPGA is a 23MHz SPI. At less than 3MB/s this is quite the bottleneck, so care must be taken to minimize the datastream between CPU and FPGA.
- Visible triangles are much more likely to be square-ish than thin horizontal or vertical lines, so any triangle is expected to cover fewer square tiles than it would line buffers making tiling a more efficient binning strategy.
- Texture caching also benefits from square tiles vs line bins as it greatly improves the spatial locality of texel accesses.

Based on all this, a tile-based rendering approach was chosen with 32x32 pixel tiles (the biggest that could reasonably be supported with the FPGA's EBRAM). The CPU would clip and bin triangles per tile and send each bin of triangles to the FPGA. The FPGA will precalculate the edge gradients and render each triangle in order to the tile buffer. Once all triangles are rendered, the active tile buffer is swapped with the display tile buffer to be transferred to the display.

## Reality

In practice, this plan didn't work out perfectly. The main issue is that the clipping of every triangle for every tile is simply too expensive on the CPU side. Alternatives could be barycentric rendering (which wouldn't require clipping or clipping on the FPGA), but both would require additional digital logic while size was already a major concern.

Size constraints also meant texturing was scrapped for the initial version, negating the texture caching benefits. Finally, the Badge.team managed to up the link speed between CPU and FPGA to 80MHz, giving up to 10MB/s throughput and greatly improving on that bottleneck.

## New Plan

To eliminate the expensive clipping operations, the GPU will be redesigned to a scanline-based renderer, similar to the original QuickSilver. QuickSilver only requires a single view-frustrum clip and an inexpensive binning by top Y-coord.


# Architecture

The QuickSilver architecture is a pipeline that accepts triangles at one end and outputs pixels to an LCD at the other. The main modules, starting from the output:

## LCD Controller
- Output: **LCD**
- Input: **Frameblock Controller**

Handles the initialization of and output to the LCD. Note that the LCD Controller writes to the display in *vertical* scanlines.

*Status: **Complete, Tested on Hardware***

## Frameblock Controller
- Output: **LCD Controller**
- Input: **Drawline** *(future: Shader)*

Manages the double-buffered pixel memory and synchronizes between Drawline and the LCD Controller. Each "frameblock" is a set of four vertical scanlines, or 4 x 240 pixels, at 16 bits per pixel.

*Status: **Complete, Tested on Hardware***

## *(future: Shader)*
- Output: **Frameblock Controller**
- Input: **Drawline**, **Cache Controller**

Computes the final pixel value from the vertex colour interpolated by CalcLine, the texture colour retrieved by the Cache Controller, and the shading options set in the triangle.

*Status: **TODO***

## Drawline
- Output: **Frameblock Controller** *(future: Shader)*
- Input: **Calcline**

Performs the rasterization of a single scanline of a triangle. This makes it responsible for the vertical interpolation of colour, texture coordinates and depth. Drawline also reads and writes to the Z-buffer to handle triangle occlusion. *(future: Z-buffer operations are moved to the Shader)*

*Status: **Near Complete, Some tests***

*Todo:*
- Test
- Connect to Shader
- Move Z-buffer operations to Shader

## Cache Controller
- Output: **Drawline** *(future: Shader)*, **Memory Controller**
- Input: **Drawline** *(future: Shader)*, **Memory Controller**

Manages the texture memory with an internal cache. All texture read and write requests go through the Cache Controller. If the requested address is found in the cache the data is returned from there, otherwise the cache is updated from the external RAM via the Memory Controller.
The cache stores data in 64-bit compressed texture blocks, separated over 2 32-bit words in the cache memory. With compression, a total 512x256 texels can be stored in the cache.
Technically, the cache has a 2-way set associative write-through architecture using least-recently used (LRU) replacement.

*Status: **Near Complete, Tested in Simulation***

*Todo:*
- Implement pixel read interface
- Connect to texture decompression
- Connect to Shader
- Add arbiter for read and write interface

## Memory Controller
- Output: **Cache Controller**
- Input: **Cache Controller**

Performs reads and writes to the external RAM. It is designed specifically to support texture block read/writes. Note that the external RAM has a (semi-)serial interface (up to 4-bit parallel in QPI mode) but can run at a higher clock speed than the main logic. The RAM is clocked at exactly twice the frequency of the main clock, and the Memory Controller logic implements the clock transition. 
Because of the (semi-)serial nature of the RAM it has no "native" data width, and because of both the clock transition and protocol overhead make larger data blocks more efficient, the Memory Controller operates in blocks of 64 bits, the size of a compressed texture block.

*Stats: **Complete, Tested on Hardware***

## Calcline
- Output: **Drawline**
- Input: **Triangle FIFO**

Reads triangles to be rendered from the Triangle FIFO and splits each triangle into scanlines, which it passes to Drawline. This makes it responsible for the horizontal interpolation of edges, colour, texture coordinates and depth. As the frameblocks are four scanlines wide, Calcline will produce up to four scanlines per triangle before either pushing the triangle back to the FIFO for the next frameblock, or the triangle is complete.

*Status: **Near Complete, To be tested***

## Triangle FIFO
- Output: **Calcline**
- Input: **Calcline**, **Command Controller**

Stores triangles to be drawn in a circular buffer. QuickSilver renders its output in strips of 4 x 240 pixels. Each strip is rendered completely and pushed to the LCD before rendering the next. This means that triangles spanning multiple strips must be stored (with their intermediate rendering state) for the next strip. This is the function of the Triangle FIFO.
QuickSilver can render many more triangles than can fit in the Triangle FIFO directly, so it is required that new triangles are provided sorted horizontally by their leftmost vertex.

*Status: **TODO***