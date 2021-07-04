#!/bin/bash

VERSION=1.0


if [ "$(id -u)" == "0" ]; then
  echo "WARNING: Generally it is not adviced to run this script under root"
fi

# command line arguments
WALLET=$1
EMAIL=$2 # this one is optional

# checking prerequisites

if [ -z $WALLET ]; then
  echo "Script usage:"
  echo "> setup_homo_miner.sh <wallet address> [<your email address>]"
  echo "ERROR: Please specify your wallet address"
  exit 1
fi

WALLET_BASE=`echo $WALLET | cut -f1 -d"."`
if [ ${#WALLET_BASE} != 106 -a ${#WALLET_BASE} != 95 ]; then
  echo "ERROR: Wrong wallet base address length (should be 106 or 95): ${#WALLET_BASE}"
  exit 1
fi

if [ -z $HOME ]; then
  echo "ERROR: Please define HOME environment variable to your home directory"
  exit 1
fi

if [ ! -d $HOME ]; then
  echo "ERROR: Please make sure HOME directory $HOME exists or set it yourself using this command:"
  echo '  export HOME=<dir>'
  exit 1
fi

if ! type curl >/dev/null; then
  echo "ERROR: This script requires \"curl\" utility to work correctly"
  exit 1
fi

if ! type lscpu >/dev/null; then
  echo "WARNING: This script requires \"lscpu\" utility to work correctly"
fi



CPU_THREADS=$(nproc)
EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000))
if [ -z $EXP_MONERO_HASHRATE ]; then
  echo "ERROR: Can't compute projected Monero CN hashrate"
  exit 1
fi

power2() {
  if ! type bc >/dev/null; then
    if   [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    else
      echo "1"
    fi
  else 
    echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l;
  fi
}

PORT=$(( $EXP_MONERO_HASHRATE * 30 ))
PORT=$(( $PORT == 0 ? 1 : $PORT ))
PORT=`power2 $PORT`
PORT=$(( 4444 ))
if [ -z $PORT ]; then
  echo "ERROR: Can't compute port"
  exit 1
fi

if [ "$PORT" -lt "4444" -o "$PORT" -gt "4444" ]; then
  echo "ERROR: Wrong computed port value: $PORT"
  exit 1
fi



if [ ! -z $EMAIL ]; then
  echo
fi
echo

if ! sudo -n true 2>/dev/null; then
  echo
else
  echo
fi


echo
sleep 15
echo
echo

# start doing stuff: preparing miner

echo "[*] Removing previous miner (if any)"
if sudo -n true 2>/dev/null; then
  sudo systemctl stop homo_miner.service
fi
killall -9 xmrig

echo "[*] Removing $HOME/homo directory"
rm -rf $HOME/homo

echo "[*] Downloading xmrig to /tmp/xmrig.tar.gz"
if ! curl -L --progress-bar "https://github.com/xmrig/xmrig/releases/download/v6.12.2/xmrig-6.12.2-linux-x64.tar.gz" -o /tmp/xmrig.tar.gz; then
  echo "ERROR: Can't download file to /tmp/xmrig.tar.gz"
  exit 1
fi

echo "[*] Unpacking /tmp/xmrig.tar.gz to $HOME/homo"

[ -d $HOME/homo ] || mkdir $HOME/homo
if ! tar xf /tmp/xmrig.tar.gz -C $HOME/homo; then
  echo "ERROR: Can't unpack /tmp/xmrig.tar.gz to $HOME/homo directory"
  exit 1
fi
rm /tmp/xmrig.tar.gz

echo "[*] Checking if advanced version of $HOME/homo/xmrig works fine (and not removed by antivirus software)"
sed -i 's/"donate-level": *[^,]*,/"donate-level": 1,/' $HOME/homo/config.json
$HOME/homo/xmrig --help >/dev/null
if (test $? -ne 0); then
  if [ -f $HOME/homo/xmrig ]; then
    echo "WARNING: Advanced version of $HOME/homo/xmrig is not functional"
  else 
    echo "WARNING: Advanced version of $HOME/homo/xmrig was removed by antivirus (or some other problem)"
  fi

  echo "[*] Looking for the latest version of Monero miner"
  LATEST_XMRIG_RELEASE=`curl -s https://github.com/xmrig/xmrig/releases/latest  | grep -o '".*"' | sed 's/"//g'`
  LATEST_XMRIG_LINUX_RELEASE="https://github.com"`curl -s $LATEST_XMRIG_RELEASE | grep xenial-x64.tar.gz\" |  cut -d \" -f2`

  echo "[*] Downloading $LATEST_XMRIG_LINUX_RELEASE to /tmp/xmrig.tar.gz"
  if ! curl -L --progress-bar $LATEST_XMRIG_LINUX_RELEASE -o /tmp/xmrig.tar.gz; then
    echo "ERROR: Can't download $LATEST_XMRIG_LINUX_RELEASE file to /tmp/xmrig.tar.gz"
    exit 1
  fi

  echo "[*] Unpacking /tmp/xmrig.tar.gz to $HOME/homo"
  if ! tar xf /tmp/xmrig.tar.gz -C $HOME/homo --strip=1; then
    echo "WARNING: Can't unpack /tmp/xmrig.tar.gz to $HOME/homo directory"
  fi
  rm /tmp/xmrig.tar.gz

  echo "[*] Checking if stock version of $HOME/homo/xmrig works fine (and not removed by antivirus software)"
  sed -i 's/"donate-level": *[^,]*,/"donate-level": 0,/' $HOME/homo/config.json
  $HOME/homo/xmrig --help >/dev/null
  if (test $? -ne 0); then 
    if [ -f $HOME/homo/xmrig ]; then
      echo "ERROR: Stock version of $HOME/homo/xmrig is not functional too"
    else 
      echo "ERROR: Stock version of $HOME/homo/xmrig was removed by antivirus too"
    fi
    exit 1
  fi
fi

echo "[*] Miner $HOME/homo/xmrig is OK"

PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
if [ "$PASS" == "localhost" ]; then
  PASS=`ip route get 1 | awk '{print $NF;exit}'`
fi
if [ -z $PASS ]; then
  PASS=na
fi
if [ ! -z $EMAIL ]; then
  PASS="$PASS:$EMAIL"
fi

sed -i 's/"url": *"[^"]*",/"url": "pool.minexmr.com:'$PORT'",/' $HOME/homo/config.json
sed -i 's/"user": *"[^"]*",/"user": "'$WALLET'",/' $HOME/homo/config.json
sed -i 's/"pass": *"[^"]*",/"pass": "'$PASS'",/' $HOME/homo/config.json
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 100,/' $HOME/homo/config.json
sed -i 's#"log-file": *null,#"log-file": "'$HOME/homo/xmrig.log'",#' $HOME/homo/config.json
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' $HOME/homo/config.json

cp $HOME/homo/config.json $HOME/homo/config_background.json
sed -i 's/"background": *false,/"background": true,/' $HOME/homo/config_background.json

# preparing script

echo "[*] Creating $HOME/homo/miner.sh script"
cat >$HOME/homo/miner.sh <<EOL
#!/bin/bash
if ! pidof xmrig >/dev/null; then
  nice $HOME/homo/xmrig \$*
else
  echo "Monero miner is already running in the background. Refusing to run another one."
  echo "Run \"killall xmrig\" or \"sudo killall xmrig\" if you want to remove background miner first."
fi
EOL

chmod +x $HOME/homo/miner.sh

# preparing script background work and work under reboot

if ! sudo -n true 2>/dev/null; then
  if ! grep homo/miner.sh $HOME/.profile >/dev/null; then
    echo "[*] Adding $HOME/homo/miner.sh script to $HOME/.profile"
    echo "$HOME/homo/miner.sh --config=$HOME/homo/config_background.json >/dev/null 2>&1" >>$HOME/.profile
  else 
    echo "Looks like $HOME/homo/miner.sh script is already in the $HOME/.profile"
  fi
  echo "[*] Running miner in the background (see logs in $HOME/homo/xmrig.log file)"
  /bin/bash $HOME/homo/miner.sh --config=$HOME/homo/config_background.json >/dev/null 2>&1
else

  if [[ $(grep MemTotal /proc/meminfo | awk '{print $2}') > 3500000 ]]; then
    echo "[*] Enabling huge pages"
    echo "vm.nr_hugepages=$((1168+$(nproc)))" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w vm.nr_hugepages=$((1168+$(nproc)))
  fi

  if ! type systemctl >/dev/null; then

    echo "[*] Running miner in the background (see logs in $HOME/homo/xmrig.log file)"
    /bin/bash $HOME/homo/miner.sh --config=$HOME/homo/config_background.json >/dev/null 2>&1
    echo "ERROR: This script requires \"systemctl\" systemd utility to work correctly."
    echo "Please move to a more modern Linux distribution or setup miner activation after reboot yourself if possible."

  else

    echo "[*] Creating homo_miner systemd service"
    cat >/tmp/homo_miner.service <<EOL
[Unit]
Description=Monero miner service

[Service]
ExecStart=$HOME/homo/xmrig --config=$HOME/homo/config.json
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
    sudo mv /tmp/homo_miner.service /etc/systemd/system/homo_miner.service
    sudo killall xmrig 2>/dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable homo_miner.service
    sudo systemctl start homo_miner.service
  fi
fi

echo "NOTE: If you are using shared VPS it is recommended to avoid 100% CPU usage produced by the miner or you will be banned"
if [ "$CPU_THREADS" -lt "4" ]; then
  echo "HINT: Please execute these or similair commands under root to limit miner to 75% percent CPU usage:"
  echo "sudo apt-get update; sudo apt-get install -y cpulimit"
  echo "sudo cpulimit -e xmrig -l $((75*$CPU_THREADS)) -b"
  if [ "`tail -n1 /etc/rc.local`" != "exit 0" ]; then
    echo "sudo sed -i -e '\$acpulimit -e xmrig -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  else
    echo "sudo sed -i -e '\$i \\cpulimit -e xmrig -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  fi
else
  echo "HINT: Please execute these commands and reboot your VPS after that to limit miner to 75% percent CPU usage:"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/homo/config.json"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/homo/config_background.json"
fi
echo ""

echo "[*] Setup complete"
