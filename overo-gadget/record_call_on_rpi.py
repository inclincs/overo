#!/usr/bin/python3
import dbus

import os
from subprocess import Popen
import signal
import soundfile as sf
import numpy as np
import time
import datetime

bus = dbus.SystemBus()
manager = dbus.Interface(bus.get_object('org.ofono', '/'),
						'org.ofono.Manager')
modems = manager.GetModems()

for path, properties in modems:

	if "org.ofono.VoiceCallManager" not in properties["Interfaces"]:
		continue
	mgr = dbus.Interface(bus.get_object('org.ofono', path),
					'org.ofono.VoiceCallManager')
	print(mgr)

	if not len(mgr.GetCalls()):
		print('Can\'t find any calls. Check to connect the device to a phone via bluetooth.')
		exit()
	
	recording_mic_proc = Popen(['pacat',
								'-r',
								'--channels',
								'1',
								'--rate',
								'16000',
								'--file-format',
								'-d', 
								'alsa_input.usb-C-Media_Electronics_Inc._USB_PnP_Sound_Device-00.analog-mono',
								'recording_mic.wav',])
	
	recording_speaker_proc = Popen(['pacat',
									'-r',
									'--channels',
									'1',
									'--rate',
									'16000',
									'--file-format',
									'-d', 
									'alsa_output.platform-bcm2835_audio.analog-stereo.monitor',
									'recording_speaker.wav',])

	
	while True:
		if not len(mgr.GetCalls()):
			recording_speaker_proc.send_signal(signal.SIGINT)
			recording_mic_proc.send_signal(signal.SIGINT)
			
			time.sleep(0.5)

			break

	mic_signal, _ = sf.read('recording_mic.wav')
	speaker_signal, _ = sf.read('recording_speaker.wav')

	mic_signal /= np.abs(mic_signal).max()
	speaker_signal /= np.abs(speaker_signal).max()

	min_len = min(len(mic_signal), len(speaker_signal))
	mic_signal, speaker_signal = mic_signal[:min_len], speaker_signal[:min_len]

	combined_signal = 0.5 * mic_signal + 0.5 * speaker_signal
	
	sf.write(datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + '.wav', combined_signal, 16000, 'PCM_16')

	os.remove('recording_mic.wav')
	os.remove('recording_speaker.wav')

