import asyncio
import json
import os
import statistics
from datetime import datetime, timedelta
from bleak import BleakScanner
import paramiko

# Define file paths
local_save_dir = "/home/sensorX/Desktop/BT/"  # Local directory on Raspberry Pi to save JSON files temporarily
os.makedirs(local_save_dir, exist_ok=True)  # Ensure the directory exists

# SSH info for the laptop
laptop_ip = "x.x.x.x"  # Replace with your laptop's IP address
laptop_username = "computer/name"  # Replace with your laptop username
laptop_password = "xxx"  # Replace with your laptop password
laptop_directory = "C:/location/to/file"  # Directory on your laptop where files will be saved

# RSSI to distance conversion
def rssi_to_distance(rssi):
    """Convert RSSI value to distance (in meters) using a simple path-loss model."""
    A = -60  # RSSI at 1 meter (calibrated value)
    n = 2.6  # Path loss exponent
    return 10 ** ((A - rssi) / (10 * n))

# Save device data to JSON
def save_to_file(devices, timestamp):
    """Save detected devices to a JSON file and transfer it via SCP."""
    try:
        json_filename = f"{local_save_dir}BTbluetoothX_scan_data{timestamp}.json"
        with open(json_filename, "w") as json_file:
            json.dump(devices, json_file, indent=4)
        print(f"Saved {len(devices)} devices to {json_filename}.")

        ssh_and_transfer(json_filename)
    except Exception as e:
        print(f"Error saving to file: {e}")

# SSH and transfer file to the laptop
def ssh_and_transfer(json_filename):
    """Transfer the JSON file to the laptop using SSH and delete it afterward."""
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(laptop_ip, username=laptop_username, password=laptop_password)

        sftp = ssh.open_sftp()
        remote_path = os.path.join(laptop_directory, os.path.basename(json_filename))
        sftp.put(json_filename, remote_path)
        print(f"Transferred {json_filename} to {remote_path}")

        os.remove(json_filename)
        print(f"Deleted {json_filename} after transfer.")

        sftp.close()
        ssh.close()
    except Exception as e:
        print(f"Failed to transfer or delete {json_filename}: {e}")

# Continuous scanning and pushing to the queue
async def continuous_scan(queue):
    """Continuously scan for BLE devices and add them to the queue."""
    def detection_callback(device, advertisement_data):
        timestamp = datetime.now().isoformat()
        device_info = {
            "timestamp": timestamp,
            "id": "sensorX",
            "name": device.name if device.name else "Unknown",
            "address": device.address,
            "rssi": advertisement_data.rssi,
            "distance": rssi_to_distance(advertisement_data.rssi),
        }
        asyncio.create_task(queue.put(device_info))
        print(f"Detected: {device_info}")

    scanner = BleakScanner(detection_callback)
    async with scanner:
        await asyncio.Future()

# Save data from the queue at regular intervals, averaging RSSI
async def save_data(queue, interval):
    """Save data from the queue at fixed intervals with averaged RSSI for each MAC address."""
    while True:
        devices_dict = {}
        try:
            while not queue.empty():
                device = await queue.get()
                mac = device["address"]

                if mac in devices_dict:
                    devices_dict[mac]["rssi_values"].append(device["rssi"])
                    devices_dict[mac]["timestamps"].append(datetime.fromisoformat(device["timestamp"]))
                else:
                    devices_dict[mac] = {
                        "id": device["id"],
                        "name": device["name"],
                        "address": device["address"],
                        "rssi_values": [device["rssi"]],
                        "timestamps": [datetime.fromisoformat(device["timestamp"])]
                    }

            if devices_dict:
                averaged_devices = []
                for mac, data in devices_dict.items():
                    avg_rssi = statistics.mean(data["rssi_values"])
                    avg_timestamp = statistics.mean([t.timestamp() for t in data["timestamps"]])
                    avg_timestamp_iso = datetime.fromtimestamp(avg_timestamp).isoformat()

                    averaged_devices.append({
                        "timestamp": avg_timestamp_iso,
                        "id": data["id"],
                        "name": data["name"],
                        "address": data["address"],
                        "rssi": avg_rssi,
                        "distance": rssi_to_distance(avg_rssi)
                    })

                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                save_to_file(averaged_devices, timestamp)
            else:
                print("No new data to save.")
        except Exception as e:
            print(f"Error processing data: {e}")
        await asyncio.sleep(interval)

# Wait until the next minute
async def wait_until_next_minute():
    now = datetime.now()
    next_minute = (now + timedelta(minutes=1)).replace(second=0, microsecond=0)
    wait_time = (next_minute - now).total_seconds()
    print(f"Waiting {wait_time:.2f} seconds until the next minute...")
    await asyncio.sleep(wait_time)
    print(f"Started at {next_minute}")

# Main function
async def main():
    await wait_until_next_minute()
    queue = asyncio.Queue()
    save_interval = 0.75  # Save data every 0.75 seconds

    scanner_task = asyncio.create_task(continuous_scan(queue))
    saver_task = asyncio.create_task(save_data(queue, save_interval))

    await asyncio.gather(scanner_task, saver_task)

if __name__ == "__main__":
    asyncio.run(main())
