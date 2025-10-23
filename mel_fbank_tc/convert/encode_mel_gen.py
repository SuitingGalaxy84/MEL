import torch
import torchaudio
from torchaudio.transforms import MelSpectrogram, InverseMelScale

NUM_MELS = 128

mel_spec = MelSpectrogram(
    sample_rate=16000,
    n_fft=512,
    win_length=480,
    hop_length=160,
    f_min=0,
    f_max=8000,
    pad="reflect",
    n_mels=NUM_MELS,
    window_fn=torch.hann_window,
    power=2.0,
)

mel_scale = mel_spec.mel_scale
fbank = mel_scale.fb
with open(f"mel_fbank_tc/convert/mel_fb_float_{NUM_MELS}.txt", "w") as f:
    i, j = fbank.shape
    for m in range(i):
        for n in range(j):
            f.write(f"{fbank[m][n].item()}\t")
        f.write("\n")
f.close()