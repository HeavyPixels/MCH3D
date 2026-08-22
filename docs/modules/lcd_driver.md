# LCD Driver
`lcd_driver.v`, `lcd_controller.v`, `lcd_interface.v`

Controls the LCD screen and displays data from the Frameblock Controller.

## Interface
### Common
| Port  | Dir | Bits | Description |
| ----- | --- | ---- | ----------- |
| `clk` | in  |   1  | Clock (36MHz) |
| `rst` | in  |   1  | Reset |

### Frameblock Controller
| Port               | Dir | Bits | Description |
| ------------------ | --- | ---- | ----------- |
| `frameblock_data`  | in  |  16  | Pixel data from the frameblock, as RGB565. |
| `frameblock_addr`  | out |  10  | Pixel address within the current frameblock. Frameblocks are vertically aligned strips, addressed as {x[1:0], y[7:0]}. |
| `frameblock_id`    | in  |   7  | ID of the currently visible frameblock. Represents x[8:2] on the screen. |
| `frameblock_next`  | out |   1  | Signal to the Frameblock Controller requesting the next frameblock. |
| `frameblock_ready` | in  |   1  | Set to high when the requested frameblock is ready. |

### LCD Interface
| Port        | Dir | Bits | Description |
| ----------- | --- | ---- | ----------- |
| `lcd_d`     | out |   8  | Data to LCD. |
| `lcd_rst`   | out |   1  | LCD reset (active low). |
| `lcd_cs`    | out |   1  | LCD chip select (active low). |
| `lcd_rs`    | out |   1  | LCD mode select. 0: command, 1: data |
| `lcd_wr`    | out |   1  | LCD write enable (active high). |
| `lcd_ready` | in  |   1  | Signal from host indicating LCD is available to the FPGA. |

## Memory Resources

| Memory       | Size (W x D) | Count   |
| ------------ | ------------ | ------- |
| LCD Init ROM |      9 x 128 | 1 EBRAM |

**Total: 1 EBRAM**

## Functional Description
The LCD Driver consists of two components: the LCD Interface and the LCD Controller. The former drives the pins to the LCD and handles the signal timing, pulling new data from the latter. The LCD Controller determines what to commands and data to send to the LCD. It operates in two modes: init mode and display mode.

### Init mode
In init mode, the LCD Controller reads commands from the 9-bit wide Init ROM. The 8 lower bits are the byte to be send to the LCD's data port (`lcd_d`) while the upper bit indicates whether the entry is a command or data word (to control `lcd_rs`), with a high bit indicating a command here.

The data in the Init ROM is played back as a sequence or script to be executed to initialize and setup the LCD. This includes the reset procedure and the configuration needed scan in the order expected by MCH3D. A Python script is provided in the tools folder which can generate the contents of the Init ROM.

For the most part, words in the Init ROM are played back directly to the LCD. However, four special commands were added to the LCD Controller on codepoints not used by the LCD itself:

| Code  | Description |
| ----- | ----------- |
| 0x100 | NOP - No operation. Does not engage the write enable in the LCD Interface. |
| 0x1FD | Set Reset. Sets the `lcd_rst` pin high. |
| 0x1FE | Clear Reset. Clears the `lcd_rst` pin to low. |
| 0x1FF | Delay. The next byte indicates the highest byte in the delay counter. |

The delay is implemented using a 24-bit counter. At 36MHz, setting the highest byte gives a resolution of 1.82ms and a range of 466ms. In practice, the delay is only used for the reset timing, which just requires certain minima and doesn't need much accuracy.

All of these special commands, including the time while the delay is active, send a NOP to the LCD Interface.

After all commands in the Init ROM have been processed, the LCD Controller switches over to display Mode.

## Display mode
In display mode, the LCD Controller reads pixel data from the currently active frameblock and sends it to the display. The access pattern for the LCD is configured to match the frameblock orientation, as vertical strips of 4 x 240 pixels, so the full frameblock is communicated in a single command.

After transmitting each frameblock the LCD Controller pulses `frameblock_next` high to indicate to the Frameblock Controller that it is ready to process the next frameblock. The Frameblock Controller immediately pulls the `frameblock_ready` signal low and the LCD Controller waits until it is high again, indicating that the next frameblock is ready to be displayed.