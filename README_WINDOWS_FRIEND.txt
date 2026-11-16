==========================================================
   PEAKCUT - WINDOWS PC PAR 24/7 SETUP GUIDE (FOR FRIEND)
==========================================================

Aapka dost apne phone se YouTube live stream clips banana chahta hai.
Aapke PC par PeakCut 24/7 background me chalega aur wo apne phone se kahin se bhi ise control kar sakta hai!

==========================================================
Agar "Python was not found" error aaya hai:
==========================================================
Windows me Python pehle se install nahi hota (Windows dummy shortcut deta hai).
Ise theek karne ke 2 aasan tareeqe hain (koi ek karein):

TAREEQA 1 (Sabse Aasan - Direct Installer):
1. Is official link se Python 3.11 download karein:
   👉 https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
2. Downloaded file par double-click karein.
3. *** IMPORTANT ***:
   Pehli screen par neeche ek tick box hoga:
   [X] "Add python.exe to PATH"
   Isko ZAROOR tick (check) karein!
4. "Install Now" par click kar dein.
5. Setup complete hone ke baad '1_SETUP.bat' dobara run karein!

TAREEQA 2 (Command Prompt / PowerShell se 1-Click):
1. Windows search me "powershell" ya "cmd" likh kar open karein.
2. Ye command paste karke Enter dabayein:
   winget install Python.Python.3.11 --accept-package-agreements --accept-source-agreements
3. Install hone ke baad window close karein aur '1_SETUP.bat' dobara run karein!

==========================================================
KAISE RUN KAREIN (Bas 2 Clicks):
==========================================================

STEP 1: SETUP KAREIN (Sirf pehli baar)
👉 Double-click karein: 1_SETUP.bat
(Ye virtual environment banayega aur AI speech model prefetch karega).

STEP 2: START KAREIN (Online Link ke sath)
👉 Double-click karein: 2_START_ONLINE.bat
Screen par ek HTTPS Link aayega (jaise: https://xxxx.trycloudflare.com/app).
Ye link apne dost ko WhatsApp / Telegram par bhej dein!

STEP 3: BAS HO GAYA!
Aapka dost apne phone se YouTube URL paste karega aur viral clips aapke PC ke 'data\exported_clips' folder me save hoti rahengi!
App chalte waqt aapka PC sleep nahi hoga (24/7 active rahega).
Band karne ke liye '3_STOP.bat' run karein ya window band karein.
==========================================================
