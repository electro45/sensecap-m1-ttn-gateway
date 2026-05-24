#!/bin/bash
# Script de reset GPIO pour SenseCAP M1 (SX1302 + SX1250)
# GPIO BCM spécifiques au SenseCAP M1 — ne pas modifier sans vérification matérielle

SX1302_RESET_PIN=17       # Reset concentrateur SX1302
SX1302_POWER_EN_PIN=18    # Power enable module RF
SX1261_RESET_PIN=5        # Reset SX1261 (LBT / spectral scan)
AD5338R_RESET_PIN=13      # Reset DAC AD5338R

WAIT_GPIO() {
    sleep 0.1
}

init() {
    # Export GPIOs si pas déjà fait
    for pin in $SX1302_RESET_PIN $SX1302_POWER_EN_PIN $SX1261_RESET_PIN $AD5338R_RESET_PIN; do
        if [ ! -d /sys/class/gpio/gpio${pin} ]; then
            echo "${pin}" > /sys/class/gpio/export
            WAIT_GPIO
        fi
    done

    # Configurer les directions
    echo "out" > /sys/class/gpio/gpio${SX1302_RESET_PIN}/direction
    echo "out" > /sys/class/gpio/gpio${SX1302_POWER_EN_PIN}/direction
    echo "out" > /sys/class/gpio/gpio${SX1261_RESET_PIN}/direction
    echo "out" > /sys/class/gpio/gpio${AD5338R_RESET_PIN}/direction
    WAIT_GPIO
}

reset() {
    echo "SenseCAP M1 reset_lgw.sh: resetting concentrator..."

    # Activer l'alimentation du module RF
    echo "1" > /sys/class/gpio/gpio${SX1302_POWER_EN_PIN}/value
    WAIT_GPIO

    # Reset SX1302
    echo "0" > /sys/class/gpio/gpio${SX1302_RESET_PIN}/value
    WAIT_GPIO
    echo "1" > /sys/class/gpio/gpio${SX1302_RESET_PIN}/value
    WAIT_GPIO
    echo "0" > /sys/class/gpio/gpio${SX1302_RESET_PIN}/value
    WAIT_GPIO

    # Reset SX1261
    echo "0" > /sys/class/gpio/gpio${SX1261_RESET_PIN}/value
    WAIT_GPIO
    echo "1" > /sys/class/gpio/gpio${SX1261_RESET_PIN}/value
    WAIT_GPIO
    echo "0" > /sys/class/gpio/gpio${SX1261_RESET_PIN}/value
    WAIT_GPIO

    # Reset AD5338R
    echo "0" > /sys/class/gpio/gpio${AD5338R_RESET_PIN}/value
    WAIT_GPIO
    echo "1" > /sys/class/gpio/gpio${AD5338R_RESET_PIN}/value
    WAIT_GPIO

    echo "reset_lgw.sh: done"
}

term() {
    echo "SenseCAP M1 reset_lgw.sh: powering off concentrator..."

    echo "0" > /sys/class/gpio/gpio${SX1302_POWER_EN_PIN}/value
    WAIT_GPIO

    for pin in $SX1302_RESET_PIN $SX1302_POWER_EN_PIN $SX1261_RESET_PIN $AD5338R_RESET_PIN; do
        echo "${pin}" > /sys/class/gpio/unexport 2>/dev/null || true
    done

    echo "reset_lgw.sh: concentrator powered off"
}

case "$1" in
    start)
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
