# Trying GanitaVeda on a phone

Two builds, both for 64-bit ARM phones (nearly every Android phone from the last several years) running Android 7 or newer:

| File | Use it for |
|---|---|
| `GanitaVeda-release-arm64.apk` (24 MB) | How the app really feels: startup, lessons, Kannada, offline |
| `GanitaVeda-profile-arm64.apk` (37 MB) | Measuring smoothness (frame timings). Slightly bigger, otherwise the same app |

Both are signed with a debug key, which is fine for testing but not for the Play Store. Install only one at a time (same app id); uninstall first to switch.

## Installing

**By cable (best, and needed for the timing numbers).** On the phone: Settings → About → tap Build number 7 times, then Developer options → USB debugging on. Connect, accept the prompt, then on the computer:

```bash
adb install -r GanitaVeda-release-arm64.apk
```

**Without a cable.** Copy the APK to the phone (USB file transfer, Drive, email to yourself), open it from Files, and allow "install unknown apps" for that app when asked.

## Things to try, in this order

1. **First launch.** Choose language, class, script. Does the School tab show chapters for your class?
2. **A whole lesson**, any of the ten. Swipe the cards, play with the interactive card (use the buttons and the slider), read the verse, switch the script (Devanagari / ಕನ್ನಡ / IAST), do the practice using the number pad, finish it. Does the kolam gain a loop on Progress?
3. **Close the app from the recent-apps list in the middle of a lesson, reopen.** It should resume on the same card.
4. **Airplane mode on**, then repeat 2. Everything should work offline.
5. **Kannada.** Settings → Language → ಕನ್ನಡ. Look for cut-off words, wrong line breaks and odd-looking text. Tell me every string that reads wrongly.
6. **Big text.** Android Settings → Display → Font size / Display size to the largest. Does anything overlap or get cut off?
7. **Dark mode**, **rotate the phone**, and the **back gesture** from inside a lesson.
8. **Explore.** Search for `kuttaka`, `ಕುಟ್ಟಕ`, `कुट्टक` (all three should find the pulveriser), open a concept, a person, the timeline, a text's reading room.
9. **TalkBack** (Settings → Accessibility): can you move through a lesson and hear sensible labels?

## Measuring smoothness (profile build)

The plan's target is at least 60 frames a second, with under 1% of frames taking longer than 16 ms. With the profile build installed and the phone connected:

```bash
adb shell dumpsys gfxinfo in.ganitaveda.app reset
# now use the app for a minute: swipe through a lesson, scroll Explore, open a verse
adb shell dumpsys gfxinfo in.ganitaveda.app | head -25
```

Look at `Janky frames:` (want under 1%) and the 90th/95th percentile frame times (want under 16 ms). Send me that block of text, and the phone model.

Also useful: start time. Close the app fully, then

```bash
adb shell am start -W -n in.ganitaveda.app/.MainActivity
```

`TotalTime` is the cold start in milliseconds (budget: 2000 on a 4 GB phone; the emulator measured about 1000).

## What to expect and what is not final

- Verse texts are marked as awaiting review and translations as "not yet proofread": that is deliberate until the reviewers approve them.
- Kannada text is a first draft.
- The pictures on the first card of each lesson are simple drawings made in code, not the final illustrations.
- There is no verse audio yet, no videos (links are listed but not pinned), and "Report a problem" has no email address set.
- Content updates are off in this build (no server yet), so the app uses the content inside it.
