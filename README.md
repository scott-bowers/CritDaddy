# CritDaddy

Plays a selected or random sound effect upon Critical Hit, Miss, or Resist.

You can select a specific sound from the list or let a random sound play from either the "positive sounds" list (for crits) or the "negative sounds" list (for misses and resists).
Comes with some default sounds that can be replaced or added to with custom files so long as you also edit the `.lua` code to list your file names - how-to below..

## Demo Video: 
https://youtu.be/py0NfN83AtA


## How to add your own soundfiles:
1. Add your file(s) to `Interface/AddOns/CritDaddy/sounds/`
2. Add the filename(s) of your custom soundfiles to the "positiveSoundFiles" or  "negativeSoundFiles" lists:
```
CritDaddy.positiveSoundFiles = {
    "kaiwow.wav",
    "oohwhee.wav",
    "potofgreed.mp3",
    "theefiecook.mp3",
    "tioccawow.wav",
    "tioccacrit.wav",
    -- Add more sound files as needed
}

CritDaddy.negativeSoundFiles = {
    "decilaff.ogg",
    -- Add more sound files as needed
}
```