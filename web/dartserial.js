globalThis.initSerial = async function () {
    const port = await navigator.serial.requestPort();

    // Wait for the serial port to open.
    await port.open({ baudRate: 9600 });

    navigator.serial.addEventListener("connect", (event) => {
        console.log("Connected!")
    });

    navigator.serial.addEventListener("disconnect", (event) => {
        console.log("DISConnected!")
    });

    const reader = port.readable.getReader();

    // Listen to data coming from the serial device.
    while (true) {
        const { value, done } = await reader.read();
        if (done) {
            // Allow the serial port to be closed later.
            reader.releaseLock();
            break;
        } else {
            // value is a Uint8Array.
            globalThis.dartSerialDataCallback(value);
        }
    }
    return true;
}