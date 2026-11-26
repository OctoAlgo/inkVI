# The scene we measure on

- Save: the prologue checkpoint in the prison (start of the game's first playable stretch), restored before each run.
- Stretch: load -> the post-load intro cutscene (streaming burst, the first ~200 s) -> Lucia idle at the cell window.
- fps: mean over world frames 300-600 (counted from the first world frame), warm shader caches, release build.
- Picture checks at the cell window: the room is lit (warm, dim), the cell's left wall and the window's wire mesh are
  present, the hair crown has no blocky squares. A dark cell means the first passes were dropped (cold pipeline
  cache, see known-issues.md).
- Faces: checked close up in the prologue's bar cutscene (eyes, teeth, cheeks, hair).
- Later checks (Chapter 1): the boat cutscene; there w300-600 is still streaming, use world frames 900-1200.
