#!/bin/bash

############ Set Environment Variables ###############

CONFIGFILE=/boot/hdmisource_config.txt

############ Function to Write to Config File ###############

set_config_var() {
lua - "$1" "$2" "$3" <<EOF > "/home/pi/temp_config"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
if line:match("^#?%s*"..key.."=.*$") then
line=key.."="..value
made_change=true
end
print(line)
end
if not made_change then
print(key.."="..value)
end
EOF
sudo cp "/home/pi/temp_config" "$3"
#rm home/pi/temp_config
}

############ Function to Read value with - from Config File ###############

get-config_var() {
lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
local val = line:match("^#?%s*"..key.."=[+-]?(.*)$")
if (val ~= nil) then
print(val)
break
end
end
EOF
}


################################### Menus ####################################



do_dummy()
{
  echo Dummy
}

do_picam()
{

  set_config_var camera "picam" $CONFIGFILE
  touch /home/pi/tmp/camera_change
}

do_C920()
{
  set_config_var camera "c920" $CONFIGFILE
  touch /home/pi/tmp/camera_change
}

do_EagleEye()
{
  set_config_var camera "eagleeye" $CONFIGFILE
  touch /home/pi/tmp/camera_change
}

do_EagleEye2()
{
  set_config_var camera "eagleeye2" $CONFIGFILE
  touch /home/pi/tmp/camera_change
}

do_EasyCap()
{
  set_config_var camera "easycap" $CONFIGFILE
  touch /home/pi/tmp/camera_change
}

do_Cam_Auto()
{
  set_config_var camera "auto" $CONFIGFILE
  touch /home/pi/tmp/camera_change
}

do_camera()
{
  camera_status=0

  # Loop round camera menu
  while [ "$camera_status" -eq 0 ] 
  do

    # Lookup parameters for Menu Info Message
    CAMERA=$(get-config_var camera $CONFIGFILE)

    if [ "$HDMIMODE" == "auto" ]; then
      INFO="  Status: HDMI Output: Auto, Camera: "$CAMERA
    else
      INFO="  Status: HDMI Output: "$HDMIMODE" "FPS:", Camera: "$CAMERA
    fi

    # Display Camera menu

    menuchoice=$(whiptail --title "HDMISource Main Menu" --menu "$INFO" 20 82 12 \
	"0 Pi Cam"   "Select the Raspberry Pi Camera" \
    "1 C920"     "Select the C920 Camera" \
	"2 EagleEye" "Select the EagleEye camera" \
	"3 EagleEye2" "Select the Second EagleEye camera" \
	"4 EasyCap"  "Select Composite Video camera" \
	"5 Auto"     "Auto selection of camera" \
	"6 Exit"     "Exit back to main Menu" \
 	3>&2 2>&1 1>&3)

    case "$menuchoice" in
	  0\ *) do_picam ;;
      1\ *) do_C920 ;;
	  2\ *) do_EagleEye ;;
	  3\ *) do_EagleEye2 ;;
	  4\ *) do_EasyCap ;;
   	  5\ *) do_Cam_Auto ;;
	  6\ *) camera_status=1 ;;
    esac
  done
}


do_hdmi_mode()
{
  HDMIMODE=$(get-config_var hdmimode $CONFIGFILE)
  Radio1=OFF
  Radio2=OFF
  Radio3=OFF
  Radio4=OFF
  Radio5=OFF

  case "$HDMIMODE" in
    auto)
      Radio1=ON
    ;;
    720p)
      Radio2=ON
    ;;
    720i)
      Radio3=ON
    ;;
    1080p)
      Radio4=ON
    ;;
    1080i)
      Radio5=ON
    ;;
    *)
      Radio1=ON
    ;;
  esac

  hdmimode=$(whiptail --title "Select HDMI Mode" --radiolist \
   "Highlight to select, press space bar and enter" 20 78 12 \
   "auto" "Use the monitor's requested mode" $Radio1 \
   "720p" "1280x720 progressive scan" $Radio2 \
   "720i" "1280x720 interlaced scan" $Radio3 \
   "1080p" "1920x1080 progressive scan" $Radio4 \
   "1080i" "1920x1080 interlaced scan" $Radio5 \
   3>&2 2>&1 1>&3)

  if [ $? -eq 0 ]; then
     set_config_var hdmimode "$hdmimode" $CONFIGFILE
     HDMIMODE=$hdmimode
  fi

  if [ "$HDMIMODE" != "auto" ]; then

    FPS=$(get-config_var fps $CONFIGFILE)
    Radio1=OFF
    Radio2=OFF
    Radio3=OFF
    Radio4=OFF
    Radio5=OFF
    Radio6=OFF
    Radio7=OFF

    case "$FPS" in
      24)
        Radio1=ON
      ;;
      25)
        Radio2=ON
      ;;
      30)
        Radio3=ON
      ;;
      50)
        Radio4=ON
      ;;
      60)
        Radio5=ON
      ;;
      100)
        Radio6=ON
      ;;
      120)
        Radio7=ON
      ;;
      *)
        Radio2=ON
      ;;
    esac

    fps=$(whiptail --title "Select Frame Rate" --radiolist \
     "Highlight to select, press space bar and enter" 20 78 12 \
     "24" "Commonly used for cinema" $Radio1 \
     "25" "Commonly used in PAL regions" $Radio2 \
     "30" "Commonly used in NTSC regions" $Radio3 \
     "50" "Commonly used in PAL regions" $Radio4 \
     "60" "Commonly used in NTSC regions" $Radio5 \
     "100" "Occasionaly used in PAL regions" $Radio6 \
     "120" "Occasionaly used in NTSC regions" $Radio7 \
     3>&2 2>&1 1>&3)

    if [ $? -eq 0 ]; then
       set_config_var fps "$fps" $CONFIGFILE
       FPS=$fps
    fi
  fi
}



do_autostart_setup()
{
  MODE_STARTUP=$(get-config_var startup $CONFIGFILE)
  Radio1=OFF
  Radio2=OFF

  case "$MODE_STARTUP" in
    hdmisource)
      Radio1=ON
    ;;
    *)
      Radio2=ON
    ;;
  esac

  chstartup=$(whiptail --title "Select Startup Mode" --radiolist \
   "Highlight to select, press space bar and enter" 20 78 12 \
   "hdmisource" "Start the HDMI Source on Boot" $Radio1 \
   "prompt" "Start with command prompt" $Radio2 \
   3>&2 2>&1 1>&3)

  if [ $? -eq 0 ]; then
     set_config_var startup "$chstartup" $CONFIGFILE
     MODE_STARTUP=$chstartup
  fi
}


do_Factory()
{
  sudo cp /home/pi/hdmisource/hdmisource_config.txt.factory /boot/hdmisource_config.txt
  whiptail --title "Done" --msgbox "Factory Settings Restored.  Press enter to continue" 8 78
}


do_system_setup()
{
  menuchoice=$(whiptail --title "Advanced Configuration Menu" --menu "Select an option" 20 78 13 \
    "1 Autostart" "Set Autostart"  \
    "2 Factory" "Restore Factory Settings" \
    "3 Show IP" " " \
    "4 WiFi Set-up" "SSID and password"  \
    "5 WiFi Off" "Turn the WiFi Off" \
    "6 Web Control" "Enable or Disable Web Control" \
    "7 Set-up EasyCap" "Set input socket and PAL/NTSC"  \
    "8 Audio Input" "Select USB Dongle or EasyCap"  \
    "9 Attenuator" "Select Output Attenuator Type"  \
    "10 Lime Status" "Check the LimeSDR Firmware Version"  \
    "11 Lime Update" "Update the LimeSDR Firmware Version"  \
    "12 Update" "Check for Updated Portsdown Software"  \
    3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) do_autostart_setup ;;
      2\ *) do_Factory   ;;
	  3\ *) do_dummy ;;
      4\ *) do_dummy ;;
      5\ *) do_dummy   ;;
      6\ *) do_dummy ;;
      7\ *) do_dummy ;;
      8\ *) do_dummy;;
      9\ *) do_dummy;;
      10\ *) do_dummy;;
      11\ *) do_dummy;;
      12\ *) do_dummy ;;
    esac
}


do_EDID_Video()
{
  reset

  printf "Extract from EDID\n"
  printf "=================\n\n"

  edid-decode /sys/class/drm/card0-HDMI-A-1/edid | grep "  DTD"
  edid-decode /sys/class/drm/card0-HDMI-A-1/edid | grep "  VIC"

  printf "\n\nPress any key to return to the main menu\n"
  read -n 1
}


do_EDID_Audio()
{
  reset

  printf "Extract from EDID\n"
  printf "=================\n\n"

  edid-decode /sys/class/drm/card0-HDMI-A-1/edid | sed -n '/Audio Data Block:/,$p' | more -n 17

  printf "\n\nPress any key to return to the main menu\n"
  read -n 1
}

do_Exit()
{
  status=1
}

do_Reboot()
{
  /home/pi/hdmisource/stop.sh
  sudo fbi -T 1 -noverbose -a /home/pi/hdmisource/images/shutdown_caption.jpg >/dev/null 2>/dev/null
  sudo systemctl stop pigpiod &               # Prevent occasional shutdown hang
  sleep 2
  sudo reboot now                             # and shutdown
}


do_Shutdown()
{
  /home/pi/hdmisource/stop.sh
  sudo fbi -T 1 -noverbose -a /home/pi/hdmisource/images/shutdown_caption.jpg >/dev/null 2>/dev/null
  sudo systemctl stop pigpiod &               # Prevent occasional shutdown hang
  sleep 2
  sudo shutdown now                           # and shutdown
}



#********************************************* MAIN MENU *********************************
#************************* Execution of Console Menu starts here *************************

status=0

# kmsprint -l | grep 'Crtc 3 '

# Loop round main menu
while [ "$status" -eq 0 ] 
  do

    # Lookup parameters for Menu Info Message
    HDMIMODE=$(get-config_var hdmimode $CONFIGFILE)
    FPS=$(get-config_var fps $CONFIGFILE)
    CAMERA=$(get-config_var camera $CONFIGFILE)
    AUDIO=$(get-config_var audio $CONFIGFILE)

    if [ "$HDMIMODE" == "auto" ]; then
      INFO="  Status: HDMI Output: Auto, Camera: "$CAMERA
    else
      INFO="  Status: HDMI Output: "$HDMIMODE" "FPS:", Camera: "$CAMERA
    fi

    # Display main menu

    menuchoice=$(whiptail --title "HDMISource Main Menu" --menu "$INFO" 20 82 12 \
	"0 Camera" "Select Active Camera ("$CAMERA" selected)" \
    "1 Audio" "Select Audio content, level and bitrate ("$AUDIO" selected)" \
	"2 HDMI Mode" "Select HDMI Output resolution and framerate" \
	"3 Config" "Adjust Advanced Settings" \
	"4 Show EDID" "Show the valid Video modes for the connected monitor" \
	"5 EDID Audio" "Show the valid Audio modes for the connected monitor" \
    "6 Exit" "Exit to the Command Prompt" \
    "7 Reboot" "Reboot the System" \
    "8 Shutdown" "Shutdown the System" \
 	3>&2 2>&1 1>&3)

        case "$menuchoice" in
	    0\ *) do_camera ;;
        1\ *) do_dummy ;;
	    2\ *) do_hdmi_mode ;;
   	    3\ *) do_system_setup ;;
	    4\ *) do_EDID_Video ;;
	    5\ *) do_EDID_Audio ;;
	    6\ *) do_Exit ;;
	    7\ *) do_Reboot ;;
        8\ *) do_Shutdown ;;
    esac
  done
exit

