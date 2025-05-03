# Advanced-3D-scanner-multi-sensors-matlab-meshlab
This system performs 3D scanning using two non-contact sensors—an IR sensor for precision and an ultrasonic sensor for extended range. Both are mounted on stepper-driven platforms. A third stepper rotates a turntable holding the object. The system creates a 3D point cloud by layering 2D scans.

Components:
• IR Sensor (Sharp GP2Y0A21): Short-range detection
• Ultrasonic Sensor (HC-SR04): Long-range surface mapping
• Stepper Motors: Control Z-axis, lateral motion, and turntable (θ-axis)
• Arduino Mega: Controls motors, sensors, and data handling
• SD Card Module: Stores scan data (.txt)
• EEPROM: Maintains scan count for file naming

Working:
 1. Initialization:
The object is placed on the turntable. On startup, EEPROM is read to generate a unique scan file name.
 2. IR Scanning:
The IR sensor performs a 360° scan in 1.8° steps. After each rotation, the sensor moves up (e.g., 0.2 cm) to scan the next layer. This continues until no object is detected within 9 cm horizontally. Data is saved as (x, y, z) in IR_xx.txt.
 3. Ultrasonic Scanning:
Triggered after IR scan completion. Follows the same layered approach with a 10 cm radius, capturing broader geometry at lower resolution.
 4. Error Handling:
On sensor or write failure, the system aborts and returns the Z-axis to the base position to avoid damage.
 5. Output:
Both scans output point cloud data suitable for MeshLab or similar software.

Features:
• Dual sensors for detail and coverage
• Layered scanning builds full 3D shape
• Automatic error recovery
• EEPROM-based scan tracking
• Fully autonomous operation

Applications:
• Rapid prototyping
• Reverse engineering
• CAD education
• Artifact digitization
