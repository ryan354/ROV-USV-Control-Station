# MAVLink Headers

This directory should contain pre-generated MAVLink v2 headers for the `ardupilotmega` dialect.

## Generate Headers

1. Install pymavlink:
   ```
   pip install pymavlink
   ```

2. Clone MAVLink definitions:
   ```
   git clone https://github.com/mavlink/mavlink.git --recursive mavlink-src
   ```

3. Generate C headers:
   ```
   python -m pymavlink.tools.mavgen --lang=C --wire-protocol=2.0 --output=. mavlink-src/message_definitions/v1.0/ardupilotmega.xml
   ```

This will create the `ardupilotmega/` directory with all required headers.
