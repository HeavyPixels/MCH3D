# Drawline
`drawline.v`

Performs the rasterization of a single scanline of a triangle. This makes it responsible for the vertical interpolation of colour, texture coordinates and depth. Drawline also reads and writes to the Z-buffer to handle triangle occlusion. *(future: Z-buffer operations are moved to the Shader)*

## Interface
### Common
| Port  | Dir | Bits | Description |
| ----- | --- | ---- | ----------- |
| `clk` | in  |   1  | Clock (36MHz) |
| `rst` | in  |   1  | Reset |

