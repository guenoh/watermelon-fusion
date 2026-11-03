# Watermelon Fusion

Watermelon merge mobile game developed in Godot 3.5

## Play in your browser

**[얼굴 합치기 플레이](https://guenoh.github.io/watermelon-fusion/)**

Open the link on a phone or computer and press **같이 놀기**. Hold anywhere in the
playfield and drag left or right: the ball follows your movement smoothly while
preserving the initial grab offset. Release to drop from its current visible
position. A quick tap or click drops at the current aim position. The next ball
keeps that position. The best score is saved in the current browser; clearing
browser storage removes it. A faster follow keeps aiming close to the finger;
reversing direction at a wall responds immediately. Mouse and touch releases use
one gesture owner, and releasing while the next ball is preparing queues one
drop. Restart cancels old gestures and loading animations before the new round.
This is a noncommercial family-play fork.

Faces use low contact friction and a gentle sideways correction only when two
different levels balance almost exactly center-on-center, so repeated centered
drops roll into a pile instead of freezing into a vertical tower.
Normal face radii grow from 26 to 126 pixels in 10-pixel steps. The final
hat portrait is level 11 and has a 252-pixel diameter, leaving room for two
final faces side by side within the 720-pixel box. This gentler size progression
gives a family round more room before reaching the danger line.

Faces occasionally speak Korean family messages in a floating bubble. Each new
queued piece independently has a **combined 2%** chance to be a rare bubble.
That roll chooses equally between the heart bomb, **수안** (blue), **수민 ×5**
(pink), and **엄마** (gold), so each type has a 1/200 overall chance. There is no guaranteed starting
item or separate inventory button; all four use the usual drag and drop.

The bomb clears nearby dropped pieces on its first contact with a face or the
box, awards their points, and protects held/preview pieces. Suan combines with
the first ordinary face he touches and upgrades its level, capped at the final
hat portrait; scoring follows a pair of that target level. Sumin replaces herself
and the first ordinary face she touches with **five total copies** of that face.
Copies are spaced within the side walls without overlapping existing dropped
pieces, and have a 1.25-second merge delay so all five can be seen before normal
merging resumes. Copy creation itself awards no points. Walls and other rare
bubbles do not consume Suan/Sumin's face-targeting ability; touching a bomb still
detonates the bomb. Reset discards pending abilities from the previous round.

Mom passes through every ball and activates only on reaching the floor, including
when she touches a side wall first. Her “빨리빨리!” speech bubble and heart burst
launch all dropped balls sideways/upward with spin, preserving them and awarding
no points for the remix itself. Upward velocity is bounded by each ball's free
headroom. A brief merge pause and eight-second danger grace let the pile shuffle;
held and preview pieces remain protected. Game over requires the same dropped
ball to remain settled above the line continuously for 3.1 seconds. Flying balls,
previews and removed balls do not count, and returning below the line clears the
warning immediately. Restarts clear the previous round's warning state.

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
