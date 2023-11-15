import struct
import socket
import random

# Define the byte and array of floats
byte_value = 1
float_array = [random.uniform(-1.0, 1.0) for _ in range(2000)]  # Creates an array of 512 random float32 numbers

# Pack the byte
packed_byte = struct.pack('B', byte_value)

# Pack the array of floats
packed_floats = b''.join(struct.pack('f', f) for f in float_array)

# Combine the packed byte and floats
packed_data = packed_byte + packed_floats

# Create a raw socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect to server
s.connect(('localhost', 3000))

# Send the packed data
s.send(packed_data)

# Close the socket
s.close()
