#!/bin/bash

# Create a 15-minute duration for the sounds
DUR=900

# Binaural Delta (200, 202)
ffmpeg -y -f lavfi -i "sine=frequency=200:duration=$DUR" -f lavfi -i "sine=frequency=202:duration=$DUR" -filter_complex "[0:a][1:a]join=inputs=2:channel_layout=stereo[a]" -map "[a]" -c:a libvorbis -q:a 1 assets/sounds/binaural_delta.ogg

# Binaural Theta (200, 206)
ffmpeg -y -f lavfi -i "sine=frequency=200:duration=$DUR" -f lavfi -i "sine=frequency=206:duration=$DUR" -filter_complex "[0:a][1:a]join=inputs=2:channel_layout=stereo[a]" -map "[a]" -c:a libvorbis -q:a 1 assets/sounds/binaural_theta.ogg

# Binaural Alpha (200, 210)
ffmpeg -y -f lavfi -i "sine=frequency=200:duration=$DUR" -f lavfi -i "sine=frequency=210:duration=$DUR" -filter_complex "[0:a][1:a]join=inputs=2:channel_layout=stereo[a]" -map "[a]" -c:a libvorbis -q:a 1 assets/sounds/binaural_alpha.ogg

# Binaural Beta (200, 220)
ffmpeg -y -f lavfi -i "sine=frequency=200:duration=$DUR" -f lavfi -i "sine=frequency=220:duration=$DUR" -filter_complex "[0:a][1:a]join=inputs=2:channel_layout=stereo[a]" -map "[a]" -c:a libvorbis -q:a 1 assets/sounds/binaural_beta.ogg

# Binaural Gamma (200, 240)
ffmpeg -y -f lavfi -i "sine=frequency=200:duration=$DUR" -f lavfi -i "sine=frequency=240:duration=$DUR" -filter_complex "[0:a][1:a]join=inputs=2:channel_layout=stereo[a]" -map "[a]" -c:a libvorbis -q:a 1 assets/sounds/binaural_gamma.ogg

# Brown Noise
ffmpeg -y -f lavfi -i "anoisesrc=c=brown:d=$DUR:a=0.5" -c:a libvorbis -q:a 1 assets/sounds/brown_noise.ogg

# Pink Noise
ffmpeg -y -f lavfi -i "anoisesrc=c=pink:d=$DUR:a=0.5" -c:a libvorbis -q:a 1 assets/sounds/pink_noise.ogg

# White Noise
ffmpeg -y -f lavfi -i "anoisesrc=c=white:d=$DUR:a=0.1" -c:a libvorbis -q:a 1 assets/sounds/white_noise.ogg

rm assets/sounds/*.wav 2>/dev/null || true

