/*
 * This example code is in the Public Domain (or CC0 licensed, at your option.)
 * Unless required by applicable law or agreed to in writing, this
 * software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.
 */

// This file contains a simple Hello World app which you can base you own
// native Badge apps on.

#include "main.h"

#include "qsapp.h"

#include "qs_core.h"
#include "qs_render.h"
#include "clipping.h"

#include <esp_timer.h>

#if PAX_DEBUG
static pax_buf_t buf;
const pax_col_t black = 0xFF000000;
const pax_col_t white = 0xFFFFFFFF;
static int current_text_line = 0;

char nibble_hex(int n){
    if(n<10){
        return '0' + n;
    } else {
        return 'A' + (n-10);
    }
}

// Updates the screen with the latest buffer.
void disp_flush() {
    ili9341_write(get_ili9341(), buf.buf);
}

void println(char* line){
    pax_draw_text(
        &buf,
        white,
        pax_font_sky_mono,
        pax_font_sky_mono->default_size,
        0.0f,
        8.0f * current_text_line,
        line);
    disp_flush();
    if(current_text_line < 29){
        current_text_line++;
    } else {
        pax_background(&buf, black);
        current_text_line = 0;
    }    
}
#else
void println(char* line){
    return;
}
#endif

extern const uint8_t fpga_bin_start[] asm("_binary_fpga_bin_start");
extern const uint8_t fpga_bin_end[] asm("_binary_fpga_bin_end");
//extern const uint8_t scene1_bin_start[] asm("_binary_scene1_bin_start");
//extern const uint8_t scene1_bin_end[] asm("_binary_scene1_bin_end");

xQueueHandle buttonQueue;
ILI9341 displayHandle;


#include <esp_log.h>
static const char *TAG = "mch2022-demo-app";

// Exits the app, returning to the launcher.
void exit_to_launcher() {
    REG_WRITE(RTC_CNTL_STORE0_REG, 0);
    esp_restart();
}

void process_inputs(){
    // Structure used to receive data.
    rp2040_input_message_t message;
    
    // Wait forever for a button press (because of portMAX_DELAY)
    xQueueReceive(buttonQueue, &message, 0);
    
    // Which button is currently pressed?
    if (message.input == RP2040_INPUT_BUTTON_HOME && message.state) {
        // If home is pressed, exit to launcher.
        exit_to_launcher();
    }
}


void app_main() {
    
    //hdmi_spi_buf = malloc(3841);
    
    ESP_LOGI(TAG, "Welcome to the template app!");

    // Initialize the screen, the I2C and the SPI busses.
    bsp_init();

    // Initialize the RP2040 (responsible for buttons, etc).
    bsp_rp2040_init();
    
    // Initialize the ICE40 support.
    bsp_ice40_init();
    
    // This queue is used to receive button presses.
    buttonQueue = get_rp2040()->queue;
    
    // Initialize graphics for the screen.
#if PAX_DEBUG
    pax_buf_init(&buf, NULL, 320, 240, PAX_BUF_16_565RGB);
    pax_background(&buf, black);
#else
    // Set and reset the LCD driver to ensure it is reset and in FPGA mode
    ili9341_init(get_ili9341());
    ili9341_deinit(get_ili9341());

    // Upload bitstream to FPGA.
    esp_err_t res = ice40_load_bitstream(get_ice40(), fpga_bin_start, fpga_bin_end - fpga_bin_start);
    if (res != ESP_OK) {
        ESP_LOGI(TAG, "ERROR: Failed to load bitstream");
        exit_to_launcher();
    }
#endif

    if(!qsapp_init()) exit_to_launcher();

    qs_button_state button;
    uint64_t prev = esp_timer_get_time();
    bool c = true;
    while (c){
        //process_inputs();
        uint64_t now = esp_timer_get_time();
        float deltatime = (now-prev) * 1e-6f;
        prev = now;
        c = qsapp_loop(button, deltatime);
    }
    
    while (1){
        //qs_render(tiles);
        process_inputs();
    }
}
