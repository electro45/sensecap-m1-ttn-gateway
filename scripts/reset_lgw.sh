#!/bin/bash
# Script de reset GPIO pour SenseCAP M1 (SX1302 + SX1250)
# GPIO BCM spécifiques au SenseCAP M1 — ne pas modifier sans vérification matérielle
# Compatible kernel 5.x (base=0) et kernel 6.x (base=512)

SX1302_RESET_PIN=17       # Reset concentrateur SX1302
SX1302_POWER_EN_PIN=18    # Power enable module RF
SX1261_RESET_PIN=5        # Reset SX1261 (LBT / spectral scan)
AD5338R_RESET_PIN=13      # Reset DAC AD5338R

# Détecter le base offset du gpiochip principal (BCM)
GPIO_BASE=$(cat /sys/class/gpio/gpiochip*/base 2>/dev/null | sort -n | head -1)
GPIO_BASE=${GPIO_BASE:-0}

SX1302_RESET=$((GPIO_BASE + SX1302_RESET_PIN))
SX1302_POWER_EN=$((GPIO_BASE + SX1302_POWER_EN_PIN))
SX1261_RESET=$((GPIO_BASE + SX1261_RESET_PIN))
AD5338R_RESET=$((GPIO_BASE + AD5338R_RESET_PIN))

WAIT_GPIO() {
    sleep 0.1
}

init() {
    for pin in $SX1302_RESET $SX1302_POWER_EN $SX1261_RESET $AD5338R_RESET; do
        if [ ! -d /sys/class/gpio/gpio${pin} ]; then
            echo "${pin}" > /sys/class/gpio/export
            WAIT_GPIO
        fi
    done

    echo "out" > /sys/class/gpio/gpio${SX1302_RESET}/direction
    echo "out" > /sys/class/gpio/gpio${SX1302_POWER_EN}/direction
    echo "out" > /sys/class/gpio/gpio${SX1261_RESET}/direction
    echo "out" > /sys/class/gpio/gpio${AD5338R_RESET}/direction
    WAIT_GPIO
}

reset() {
    echo "SenseCAP M1 reset_lgw.sh: resetting concentrator (GPIO base=${GPIO_BASE})..."

    echo "1" > /sys/class/gpio/gpio${SX1302_POWER_EN}/value
    WAIT_GPIO

    echo "1" > /sys/class/gpio/gpio${SX1302_RESET}/value
    WAIT_GPIO
    echo "0" > /sys/class/gpio/gpio${SX1302_RESET}/value
    WAIT_GPIO

    echo "0" > /sys/class/gpio/gpio${SX1261_RESET}/value
    WAIT_GPIO
    echo "1" > /sys/class/gpio/gpio${SX1261_RESET}/value
    WAIT_GPIO

    echo "0" > /sys/class/gpio/gpio${AD5338R_RESET}/value
    WAIT_GPIO
    echo "1" > /sys/class/gpio/gpio${AD5338R_RESET}/value
    WAIT_GPIO

    echo "reset_lgw.sh: done"
}

term() {
    echo "SenseCAP M1 reset_lgw.sh: powering off concentrator..."

    echo "0" > /sys/class/gpio/gpio${SX1302_POWER_EN}/value
    WAIT_GPIO

    for pin in $SX1302_RESET $SX1302_POWER_EN $SX1261_RESET $AD5338R_RESET; do
        echo "${pin}" > /sys/class/gpio/unexport 2>/dev/null || true
    done

    echo "reset_lgw.sh: concentrator powered off"
}

case "$1" in
    start)
        term 2>/dev/null || true
        init
        reset
        ;;
    stop)
        init
        term
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
