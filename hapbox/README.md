# HAPBox

An instance of a [HAP](https://github.com/mtrudel/hap) server that does some
custom stuff for our house. Currently, it controls a 
[KLI-312](https://www.veluxsolutions.com/apps/LPI.nsf/0/264B37C2E35FC5C385257A460070BBFB/%24file/KLI%20310-311-312%20Remote.pdf)
blind controller dead-bug wired to
a [MCP23017](https://ww1.microchip.com/downloads/aemDocuments/documents/APID/ProductDocuments/DataSheets/MCP23017-Data-Sheet-DS20001952.pdf)
I2C GPIO chip, running as a Docker container on our [house Raspberry
Pi](https://github.com/mtrudel/pibox).
