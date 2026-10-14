# 3. Sanskrit from GRETIL, as analytic (sandhi-free) text

Status: accepted, needs Sanskrit reviewer confirmation

The plan names the Sanskrit Library XML Līlāvatī; the same Hayashi e-text is on GRETIL
(CC BY-NC-SA 4.0) alongside the Āryabhaṭīya (Shukla/Feller) and Brāhmasphuṭasiddhānta
(Dvivedin/Hayashi), so all three come from one place with one licence.

The GRETIL files are IAST with sandhi resolved and compounds hyphenated. The ingester
keeps each source line verbatim (`source_text`), strips editorial markup, and generates
Devanagari, which round-trips exactly through IAST for every verse. We do **not**
re-apply sandhi: that would be editing the text. The app therefore shows the analytic
form, and every verse is `review: unreviewed` until the Sanskrit reviewer approves it.
If the reviewer prefers continuous text, the source must be a printed edition typed and
checked by a person, never generated.

Āryabhaṭīya root verses are interleaved with Bhāskara I's commentary; a person picks
each by its exact lines (`tools/ingest/aryabhatiya_ganitapada_anchors.yaml`). Verses 16
and 21 and the first halves of 6, 7, 9, 17 and 27 are still to be located.
