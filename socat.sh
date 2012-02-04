socat -v tcp-l:9999,reuseaddr,fork /dev/ttyACM0,b19200,echo=0,raw
