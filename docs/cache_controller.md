# Cache Controller
`cache_controller.v`

Builds a 2-way set associative write-through texture cache. The cache built specifically for DXT1-compressed textures:
- Addresses are composed from UV-coordinates that are swizzled to produce memory coordinates,
- Cache lines and minimum write size are 64-bits - a single DXT1 block.
- Texture blocks remain compressed in cache, but are decompressed to produce an output pixel on read.

## Interface
### Common
| Port  | Dir | Bits | Description |
| ----- | --- | ---- | ----------- |
| `clk` | in  |   1  | Clock (36MHz) |
| `rst` | in  |   1  | Reset |

### Drawline / Command Interface
| Port      | Dir | Bits | Description |
| --------- | --- | ---- | ----------- |
| `u`       | in  |  12  | U-coordinate |
| `v`       | in  |  12  | V-coordinate |
| `read`    | in  |   1  | Read request. Keep high until `accept`. Lower the cycle after `accept`. |
| `write`   | in  |   1  | Write request. Keep high until `accept`. Lower the cycle after `accept`. |
| `data_in` | in  |  64  | Data to be written for a write request. |
| `accept`  | out |   1  | Accept signal. Pulses for one cycle to accept either `read` or `write`. |

### Pixel Output
| Port          | Dir | Bits | Description |
| ------------- | --- | ---- | ----------- |
| `pixel_out`   | out |  16  | Decoded output pixel. |
| `pixel_ready` | out |   1  | Ready signal. Pulses for one cycle to when the pixel is ready. |

### Memory Controller
| Port         | Dir | Bits | Description |
| ------------ | --- | ---- | ----------- |
| `mem_addr`   | out |  20  | Upper 20 bits of the memory address. The lower 4 bits are always 0 to align with 64-bit blocks. |
| `mem_read`   | out |   1  | Read request. |
| `mem_write`  | out |   1  | Write request. |
| `mem_ready`  | in  |   1  | Data available on `mem_rddata`. Pulses *twice* for each 64-bit block, for upper and lower 32-bit halves. |
| `mem_rddata` | in  |  32  | Returned data from read *or* currently being written to memory. |
| `mem_wrdata` | out |  64  | Data to be written. |

## Memory Resources

| Memory    | Size (W x D) | Count   |
| --------- | ------------ | ------- |
| Cache RAM |  32 x 16384  | 2 SPRAM |
| Tag RAM   |  16 x  4096  | 1 SPRAM |
| LRU RAM   |   1 x  4096  | 1 EBRAM |

**Total: 3 SPRAM, 1 EBRAM**

## Functional Description
### Addressing
Textures are compressed using DXT1 texture compression, which uses fixed-size blocks of 64 bits to represent a grid of 4x4 pixels. These blocks will serve as the basic unit for the cache, both as the cache line size and as the minimum write size.

The external address interface is presented as seperate U and V coordinates, as this will be values calculated by the DrawLine module. To calculate the memory address, the U and V coordinates are 'swizzled', alternating bits from each to produce a square (instead of linear) addressing pattern:
```
23                     0
|                      |
VUVUVUVUVUVUVUVUVUVUVVUU
```
The lowest four bits are *not* swizzled as these address within the texture block.

For the cache, the address is further divided into three parts:

```
23    16 15         4 3  0
|      | |          | |  |
VUVUVUVU VUVUVUVUVUVU VVUU
      |          |      \- Offset
      |          \-------- Index
      \------------------- Tag
```

- The **Offset** describes the location within the cache line. As the cache lines match the texture blocks in this case it addresses individual pixels within a compressed block. The cache logic ignores this logic and passes it to the texture decoder.
- The **Index** describes the location within the cache. Every data block that shares an index also shares a location within the cache.
- The **Tag** indentifies which specific memory block is currently stored in a cache location.

### Associativity
The implemented cache is *2-way set associative*, meaning that each index actually corresponds to *two* locations within the cache memory, together referred to as a **set**. To determine which block is stored in every location in every set, the tag for each location is stored seperately in the Tag RAM. When reading from the cache the tag of the requested address is compared to *both* tags. If either of the stored tags match the requested tag the cache "hits" and returns the corresponding data from the Cache RAM.

### Replacement
If neither tag matches the cache "misses" and needs to retrieve the data from the main memory. That data is both returned to resolve the read request and stored in the cache for future requests. Of course, to store the data in the cache, one of the two lines in the set must be overwritten. A replacement policy determines which of the two lines will be overwritten, which in this implementation is the *Least Recently Used (LRU)*. A single bit flag is kept for every *set* in the cache which determines whether Line A or Line B was the least recent used, and is written to whenever either line is accessed via hit, miss or write.

The LRU strategy was chosen as it is quite simple to implement

### Writing
Two main decisions determine the writing strategy for a cache: whether to write the new data immediately to the main memory on a write hit (*write-through*) or only when the line is evicted (*write-back*), and whether to update the cache line on a write miss (*allocate*) or only write to main memory (*no allocate*). A fifth method would be a *write-around* which ignores the cache entirely on writes, only writes to main memory, and simply sets a 'stale' flag on hits.

Various sources have things to say about which write strategies perform well or "make sense", but this is usually written excusively from the perspective of CPU cache. The access patterns of the texture cache are quite a bit different, leading to different tradeoffs. The write size for this implementation is fixed at 64 bits, a full cache line. This eliminates the mandatory read on miss for *allocate* strategies making the allocation essentially "free". Timing requirements are also different between reads and writes, as writes are usually done either in vertical blanking or in dedicated loading screens, while reads are done while rendering and are both bandwidth- and latency-sensitive.

With that in mind, the strategy chosen for this implementation is *write-through with allocation*. A write-back implementation would be slower for reading, as it would (potentially) require a write to main memory on a read miss. A write-around implementation would add a mandatory miss on the first read, which is a relatively minor cost, but also requires a stale flag per cache line, a not insignificant 8kb or 2 EBRAM of additional memory. As mentioned before, the allocation is basically free and avoids the mandatory miss on first read.
