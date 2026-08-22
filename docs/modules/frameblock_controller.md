# Frameblock controller
`frameblock_controller.v`

The frameblock is a double-buffered block of 4 x 256 pixels acting as a partial framebuffer. While triangles are drawn to one buffer, the other buffer is written to the screen.

## Interface
### Common
| Port  | Dir | Bits | Description |
| ----- | --- | ---- | ----------- |
| `clk` | in  |   1  | Clock (36MHz) |
| `rst` | in  |   1  | Reset |

### Draw side
| Port          | Dir | Bits | Description |
| ------------- | --- | ---- | ----------- |
| `draw_wrdata` | in  |  16  | Write data. |
| `draw_wraddr` | in  |  10  | Write address. |
| `draw_we`     | in  |   1  | Write enable. |
| `draw_rddata` | out |  16  | Read data. |
| `draw_rdaddr` | in  |  10  | Read address. |
| `draw_id`     | in  |   7  | ID to be assigned to the current frameblock. Read on `draw_next`. |
| `draw_next`   | in  |   1  | Signal from the drawing controller that the current frameblock is complete and a new frameblock is requested. |
| `draw_ready`  | out |   1  | Set to high when a new frameblock is ready. |

### Display side
| Port             | Dir | Bits | Description |
| ---------------- | --- | ---- | ----------- |
| `display_rddata` | out |  16  | Read data. |
| `display_rdaddr` | in  |  10  | Read address. |
| `display_id`     | out |   7  | ID of the currently visible frameblock. |
| `display_next`   | in  |   1  | Signal from the display controller requesting the next frameblock. |
| `display_ready`  | out |   1  | Set to high when the requested frameblock is ready. |

## Memory Resources

| Memory           | Size (W x D) | Count   |
| ---------------- | ------------ | ------- |
| Frameblock RAM A |    16 x 1024 | 4 EBRAM |
| Frameblock RAM B |    16 x 1024 | 4 EBRAM |

**Total: 8 EBRAM**

## Functional Description
The Frameblock Controller contains two internal buffers that are exchanged with a handshake protocol: Each side signals it has finished accessing the current frameblock by pulsing their respective `next` signal. The Frameblock Controller responds by setting the corresponding `ready` signal to low on the next cycle. Once both sides have signaled `next`, the RAM ports are exchanged (along with the ID register) and the `ready` signals are raised again.
