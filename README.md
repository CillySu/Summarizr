# 🎥 Summarizr

<div align="center">
  <img src="https://i.imgur.com/lQZlmVY.png" alt="Summarizr Logo" width="200"/>
</div>

> A bash script (currently written for MacOS) that uses `Whisper.cpp` and `Ollama` to summarize or manipulate videos. Built on `yt-dlp`, it works across a wide range of online platforms and also accepts local video files.

---

## 📝 Table of Contents
- [🛠 Installation](#-installation)
- [🚀 Usage](#-usage)
- [🔧 Dependencies](#-dependencies)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

---

## 🛠 Installation

```
git clone https://github.com/CillySu/Summarizr.git
cd Summarizr
chmod +x Summarizr.sh
```

---

## 🚀 Usage

### Online Videos
```
./Summarizr.sh [URL] --prompt [PROMPT] --model [MODEL]
```

### Local Videos
```
./Summarizr.sh [LOCAL_FILE] --prompt [PROMPT] --model [MODEL]
```

---

## 🔧 Dependencies
Summarizr is built on:
- yt-dlp
- Whisper.cpp
- Ollama
- ffmpeg
- Python 3.10

### Install Dependencies

#### MacOS
If you haven't yet installed [Brew](https://brew.sh):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

First download and install [Ollama](https://ollama.ai/)
```bash
xcode-select --install
brew install ffmpeg
brew install yt-dlp
brew install clang
brew install gcc
pip install ane_transformers
pip install openai-whisper
pip install coremltools
cd ~
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
make
make large
```



---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Added xyz'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request

---

## 📜 License

MIT License. See `LICENSE` for more information.
