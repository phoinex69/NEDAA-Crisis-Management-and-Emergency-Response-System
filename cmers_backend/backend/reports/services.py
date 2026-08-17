from notifications.services import notify_sos_contacts


def handle_sos_emergency_contacts(report):
    notify_sos_contacts(report)


def transcribe_audio_locally(audio_file_path):
    print('[Voice] Transcription service not active in this build.')
    print(f'[Voice] Audio saved at: {audio_file_path}')
    return None
