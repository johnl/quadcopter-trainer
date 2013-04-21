# Quadcopter trainer

A simple game to practice flying a quadcopter aircraft. It makes no
attempt to seriously simulate real physics or even a real a
quadcopter. Instead, it aims to just help you become familiar with the
transposing of controls as the aircraft rotates around (something I
have a particular problem with).

It's meant to be controlled using your real radio control, via an
ArduPilot controller. Just connect your ArduPilot APM device and it
should auto-detect the device, and enter a calibration mode. Just move
the controls to all their extremes and hit space when you're done.

If an ArduPilot controller isn't detected, it skips calibration and
goes into keyboard control mode. You can then control the aircraft
with the cursor keys for roll and pitch, and A and S for yaw.

A little more info and a video of it in action here:

http://johnleach.co.uk/words/1431/quadcopter-training-game

## Requirements

It requires Ruby, and the game library I use, Gosu, requires a few
native dependencies. The following gets you them on Ubuntu:

    sudo apt-get install build-essential freeglut3-dev libfreeimage-dev libgl1-mesa-dev libopenal-dev libpango1.0-dev libsdl-ttf2.0-dev libsndfile-dev libxinerama-dev

It's only ever been tested on Linux, so I doubt it'll work on any
other platform without modifications.

(c) Copyright John Leach 2013

http://johnleach.co.uk

http://johnleach.co.uk/words/category/tech/quadcopter

Released until the terms of the GNU General Public License v3
