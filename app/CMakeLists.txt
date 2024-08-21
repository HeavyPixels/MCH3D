# This example code is in the Public Domain (or CC0 licensed, at your option.)
# Unless required by applicable law or agreed to in writing, this
# software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.

idf_component_register(
    SRCS "main.c"
         "qs_core.c"
         "qs_render.c"
         "clipping.c"
         "st_nicc.c"
         "qsapp.c"
         "bitval.c"
         "types.c"
         "precalc.c"
    INCLUDE_DIRS "."
                 "include"
    EMBED_FILES ${project_dir}/resources/fpga.bin
                ${project_dir}/resources/scene1.bin
)
