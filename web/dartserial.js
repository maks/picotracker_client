opened = false;

globalThis.initSerial = async function () {
    const filter = { usbVendorId: 0xcafe, usbProductId: 0x4009 };
    const port = await navigator.serial.requestPort({ filters: [filter] });

    // Wait for the serial port to open.
    await port.open({ baudRate: 9600 });
    opened = true;

    navigator.serial.addEventListener("connect", async (event) => {
        console.log("Connected!", event);
        if (!opened) {
            const nuport = event.target;
            // reopen port again
            await nuport.open({ baudRate: 9600 });
            opened = true;
            readData(nuport);
        }
    });

    navigator.serial.addEventListener("disconnect", (event) => {
        console.log("DISConnected!", event);
        opened = false;
    });
    readData(port);
    return true;
}

async function readData(port) {
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
}