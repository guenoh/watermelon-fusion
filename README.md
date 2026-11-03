# Watermelon Fusion

Watermelon merge mobile game developed in Godot 3.5

## Play in your browser

**[얼굴 합치기 플레이](https://guenoh.github.io/watermelon-fusion/)**

Open the link on a phone or computer and press **같이 놀기**. Hold anywhere in the
playfield and drag left or right: the ball follows your movement smoothly while
preserving the initial grab offset. Release to drop from its current visible
position. A quick tap or click drops at the current aim position. The next ball
keeps that position. The best score is saved in the current browser; clearing
browser storage removes it. This is a noncommercial family-play fork.

Faces occasionally speak Korean family messages in a floating bubble. Each new
queued piece independently has a 1% chance to be a heart bomb instead of a face;
there is no guaranteed starting bomb or separate inventory button. Drag and drop
the bomb normally. Its first contact with a face or the box clears nearby dropped
pieces, awards their points, and leaves the held/preview pieces intact. A 1%
chance is independent each time, not a guaranteed bomb every 100 pieces.

Korean text uses a renamed subset of Noto Sans KR under the SIL Open Font License;
see `Game/HUD/Fonts/OFL.txt`.

This fork adds personal face-ball artwork supplied by the family, eleven colored
and numbered merge levels, a Korean web launch screen, a portrait browser canvas,
and automatic GitHub Pages builds. The final level wears the traditional hat.
The original game rules and author attribution are preserved. The web build uses
the GLES2 / WebGL 1 renderer, CPU particles, and a simple translucent menu backdrop
for browser compatibility. No WebGL 2 or screen-copy blur shader is required.

The original project license below covers the original game. Personal family
portrait artwork in `Game/Personal/` is separate content; see that folder's
`NOTICE.md`. Permission to use the original game is not permission to reuse
these personal portraits.

Changes pushed to `main` are exported with Godot 3.5.3 and deployed by
`.github/workflows/deploy-web.yml`. The generated game files are build artifacts
and are not committed to the source repository.

## Screenshots

<img src="https://github.com/koopmyers/watermelon-fusion/assets/16466001/dfbbf201-f7b8-4bed-84fd-79e197470200" alt="drawing" width="200"/>
<img src="https://github.com/koopmyers/watermelon-fusion/assets/16466001/8f8b707e-d622-415a-a45f-6d80cd6dcc84" alt="drawing" width="200"/>
<img src="https://github.com/koopmyers/watermelon-fusion/assets/16466001/7371dc72-4430-4fbd-98b5-09a1d48b99d1" alt="drawing" width="200"/>


## Licence
<p xmlns:cc="http://creativecommons.org/ns#" xmlns:dct="http://purl.org/dc/terms/"><a property="dct:title" rel="cc:attributionURL" href="https://github.com/koopmyers/watermelon-fusion">Watermelon Fusion</a> by <a rel="cc:attributionURL dct:creator" property="cc:attributionName" href="https://github.com/koopmyers">Koop Myers</a> is licensed under <a href="http://creativecommons.org/licenses/by-nc-sa/4.0/?ref=chooser-v1" target="_blank" rel="license noopener noreferrer" style="display:inline-block;">Attribution-NonCommercial-ShareAlike 4.0 International<img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/cc.svg?ref=chooser-v1"><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/by.svg?ref=chooser-v1"><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/nc.svg?ref=chooser-v1"><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/sa.svg?ref=chooser-v1"></a></p>
