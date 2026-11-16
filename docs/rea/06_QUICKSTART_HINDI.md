# 06. Quick-Start Guide (Roman Hindi / Hinglish)

Namaste! Ye guide aapko PeakCut ko apne Windows PC par bina kisi technical jhanjhat ke chalane aur 24/7 continuous YouTube livestream se automatic viral clips nikalne ka aasan tarika batati hai.

---

## 1. Shuruat Se Pehle Kya Chahiye?

Aapke PC me ye 3 cheezein honi chahiye:
1. **Windows 10 ya 11 (64-bit)**
2. **Python 3.11** (Install karte waqt *"Add Python to PATH"* par tick zaroor karein)
3. **FFmpeg** (CMD me `winget install Gyan.FFmpeg` likhein ya install karein)
4. Kam se kam **15–20 GB free space** aapki hard drive me.

---

## 2. 1-Click Setup (Pehli Baar)

1. PeakCut folder kholein.
2. `scripts\windows\setup.bat` par **double-click** karein.
3. Ye script khud-b-khud:
   - Sabhi zaroori packages install karega.
   - Hindi aur English samajhne wala Whisper AI speech model (~140 MB) download karega.
   - Folder structure ready kar dega.
4. Jab screen par *"Setup completed successfully"* likha aaye, to window band kar dein.

---

## 3. PeakCut Start Kaise Karein (24/7 Mode)

1. `scripts\windows\start.bat` par **double-click** karein.
2. Ek black window khulegi aur aapka browser automatically **http://127.0.0.1:8765** par open ho jayega.
3. **Important**: Ye script aapke Windows PC ko beech me sleep/lock hone se rokti hai, taaki agar aap PC chhod kar chale bhi jayein, to 24/7 recording bina ruke chalti rahe!

---

## 4. Live Stream Link Daal Kar Clips Banana

1. Browser me PeakCut dashboard kholein (`http://127.0.0.1:8765`).
2. **"Paste video or stream link"** box me apna authorized YouTube livestream link paste karein (jaise: `https://youtube.com/watch?v=...` ya `https://youtube.com/@ChannelName`).
3. Stream ka category chunein:
   - **Gaming** (Loud scream, clutch moment, rage)
   - **Podcast** (Strong debate, deep conversation)
   - **IRL / Reactions** (Shock, comedy, laugh)
   - **General**
4. Layout chunein:
   - **Blur / Zoom / Crop** (Vertical 9:16 Shorts format)
   - **Original** (Horizontal YouTube video format)
5. **Start** button dabayein!

---

## 5. Clips Kahan Milengi?

- **Dashboard me**: Naye bane clips card ban kar samne aate rahenge. Har clip me moment ka score (0-100), hook title, aur transcript likha hoga.
- **Aapke Computer me**: Sabhi final ready clips automatically is folder me save hoti hain:
  ```
  PeakCut\data\exported_clips\
  ```
  Aap direct in `.mp4` videos ko drag-and-drop karke YouTube Shorts ya Instagram Reels par upload kar sakte hain!

---

## 6. Pause, Resume aur Stop Controls

- **Pause**: Agar streamer break par gaya hai ya internet slow ho raha hai, to dashboard me **Pause** button dabayein.
- **Resume**: Wapas capture shuru karne ke liye **Resume** dabayein.
- **Stop**: Stream khatam hone par **Stop** dabayein. Last bachi hui clips render ho jayengi aur background process band ho jayega.
- **Emergency Stop**: Agar browser band ho jaye, to bas `scripts\windows\stop.bat` par double-click karein, sab kuch safely band ho jayega.

---

## 7. Zaroori Baatein (Tips)

1. **Internet Disconnect**: Agar internet 1-2 minute ke liye chala jata hai, to pareshan na hon. PeakCut automatically 15 baar retry karega aur wapas connect ho jayega.
2. **Quality Over Quantity**: Agar stream me kuch interesting nahi ho raha (silent hai ya boring gameplay chal raha hai), to system zabardasti kachra clips nahi banayega. Sirf genuine energetic moments hi clip honge!
3. **Disk Space Safety**: Agar aapki C-Drive me 5 GB se kam space bachega, to PeakCut aapke PC ko crash hone se bachane ke liye khud hi recording rok dega.
