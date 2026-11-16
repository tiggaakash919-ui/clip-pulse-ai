# 04. Speech Recognition Models & Hardware Sizing Guide

## 1. Upstream Default vs. Multilingual Whisper Comparison

Upstream PeakCut ships with `sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8`, an English-only Conformer Transducer model. While fast for pure English, it cannot transcribe Hindi, Hinglish, or Devanagari script.

To support Hindi, Hinglish (code-switching), and mixed Indian streaming content, PeakCut's REA pipeline introduces support for **sherpa-onnx Whisper ONNX** models.

| Speech Model | Architecture | Size | Language Support | Hindi & Hinglish Quality | Word Timestamps | Recommended Hardware |
|---|---|---|---|---|---|---|
| **sherpa-onnx-whisper-base** *(Default in REA)* | Encoder-Decoder Transformer | **~140 MB** | 99+ Languages | **Very Good** for conversational Hindi/English stream chatter | **Yes** (via byte-level BPE alignment) | Intel/AMD 4-core CPU or any NVIDIA GPU |
| **sherpa-onnx-whisper-tiny** | Encoder-Decoder Transformer | **~75 MB** | 99+ Languages | Moderate (occasional mishearings on fast accents) | **Yes** | Low-power laptops / dual-core CPUs |
| **sherpa-onnx-whisper-small** | Encoder-Decoder Transformer | **~460 MB** | 99+ Languages | **High accuracy** on noisy audio & overlapping speech | **Yes** | 6-core+ CPU or NVIDIA GPU (>= 4 GB VRAM) |
| **sherpa-onnx-nemo-parakeet-0.6b** *(Upstream)* | Conformer TDT Transducer | **~480 MB** | **English Only** | **Unsupported** (outputs gibberish on Hindi) | **Yes** | 4-core CPU |

---

## 2. Hardware Tiers & Performance Expectations

Real-Time Factor (RTF) measures the processing speed: an RTF of 0.2 means 10 seconds of speech is transcribed in 2 seconds. For 24/7 continuous live streaming in 6-second segments, RTF must be **< 0.8** to prevent backlog.

### Tier 1: Minimum (Budget Laptop / Low-End PC)
- **CPU**: Intel Core i3 (8th Gen+) or AMD Ryzen 3 (4 cores / 4 threads)
- **RAM**: 8 GB DDR4
- **GPU**: Integrated Graphics (Intel UHD / Vega)
- **Disk**: 20 GB free SSD storage
- **Model Recommendation**: `sherpa-onnx-whisper-tiny` or `sherpa-onnx-whisper-base`
- **Expected RTF**: ~0.35–0.50 on CPU (keeps up comfortably with a single livestream)

### Tier 2: Recommended (Standard Desktop / Mid-Range PC)
- **CPU**: Intel Core i5 / AMD Ryzen 5 (6 cores / 12 threads)
- **RAM**: 16 GB DDR4/DDR5
- **GPU**: NVIDIA GTX 1660 / RTX 3050 / RTX 4060 (>= 4 GB VRAM)
- **Disk**: 50 GB free NVMe SSD storage
- **Model Recommendation**: `sherpa-onnx-whisper-base` (with CUDA or multi-threaded CPU)
- **Expected RTF**: ~0.08–0.15 (sub-second segment transcription)

### Tier 3: Power User / Production Station
- **CPU**: Intel Core i7 / AMD Ryzen 7+
- **RAM**: 32 GB RAM
- **GPU**: NVIDIA RTX 3070 / RTX 4070+ (8 GB+ VRAM)
- **Disk**: 100 GB+ free NVMe SSD storage
- **Model Recommendation**: `sherpa-onnx-whisper-small`
- **Expected RTF**: ~0.04–0.08 (near-instantaneous analysis)

---

## 3. Switching Speech Models

To select a different model, update your `.env` file before starting the application:

```bash
# Model family: "whisper" or "transducer"
PEAKCUT_ASR_FAMILY=whisper

# Pretrained model identifier
PEAKCUT_MODEL=sherpa-onnx-whisper-base

# Recognition language: "hi" for Hindi, "en" for English, or "auto"
PEAKCUT_ASR_LANGUAGE=hi
```

To pre-download the model files:
```powershell
.\.venv\Scripts\python.exe -m studio.fetch_model
```
