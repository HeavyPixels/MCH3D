# MCH3D

A 3D accelerator project for the MCH 2022 Badge. Includes a demo app that displays the famous ST-NICC 2000 demo by Oxygene as a benchmark of sorts.

## Demo running on the tile-based renderer

https://hpxl.nu/v/MCH3D_demo.mp4

# Status

Work is ongoing to convert the original tile-based design into chunky scanline-based renderer.

- Both the FGPA core and demo app have been converted to use the new architecture, though further testing and debugging is required.
- Current version supports Gouraud shading only, texture supported is to be added later.
- A cache and memory controller have been implemented for future texture support, but have not been integrated yet.

# Usage

The full Verilog source is included in the `fpga` folder, but some parts are created using Lattice Radiant IP (e.g PLLs and RAM). I've included the IP parameter files in the `ip cfg` folder so they can be recreated in your preferred development environment. Note that the synthesized bitstream for the FPGA is included in the demo application, so no need to set up the full FPGA development environment if you just want to test or develop the software side.

The C source of the demo application is included in the `app` folder, and is intended to be compiled with the Badge.team's custom IDF. The easiest way to get started is to clone the [Template App](https://github.com/badgeteam/mch2022-template-app), test that it builds and runs on your badge, and then replace the code in the `main` folder of the template with the code in the `app` folder in this repo.