/*
 * Copyright (c) 2022 Dhruva Gole
 *
 * SPDX-License-Identifier: Apache-2.0
 */

// TODO: correctly handle these legacy defines
#define MOSI    11
#define MISO    12
#define SCK     13
#define SS      10
#define SDA     0
#define SCL     0

/* Arduino_APDS9960 library */
#define PIN_INT_APDS 26 /* D26 - P0.19 */
#define APDS9960_INT_PIN PIN_INT_APDS
#define APDS9960_WIRE_INSTANCE Wire1

#define ARDUINO_ARDUINO_NANO33BLE /* This is required for the proper functioning of some libraries (i.e. Arduino_LPS22HB, Arduino_HS300x. etc. )*/