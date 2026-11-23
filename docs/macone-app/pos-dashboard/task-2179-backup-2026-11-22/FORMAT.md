# Task 2179: how to rebuild it in the same format

Backup of revision 19, taken on 22/11/2026 before the Task was cleared. The old results are a format reference only. Never copy them into the new Task.

## Files

| File | Content |
|---|---|
| description.html | The exact Description |
| template_story_with_placeholders.html | The story text with 15 empty places, QA_BLOCK_0 to QA_BLOCK_14 |
| template_qa_blocks.html | The 15 old QA blocks, for markup and styles |
| workitem.json, comments.json | All fields, relations and comments (0 comments) |
| images/, images-map.tsv | Every linked image or file with its original URL |
| attachments/ | The two files attached to the work item |

Known bad file: the TC-041 YTD image (Figure 77) is a VS Code screenshot. Never reuse it.

## Layout

The Description is the full story text. A QA block follows the story section that it tests.

| Block | Place | Cases |
|---|---|---|
| 0 | Top, bordered box | Summary: execution info, results counters, QA data, bugs, open questions, blocked and not run |
| 1 | After 3. Dashboard Navigation | 001, 002, 003, 004 |
| 2 | After 4.1 Daily Sales KPI | 005, 008, 068, 006, 007, 011, 012, 009, 010, 067 |
| 3 | After 4.2 Invoices Today | 013, 069, 070, 014, 015, 016 |
| 4 | After 4.3 Work Orders Today | 017, 018, 071 |
| 5 | After 4.4 Inventory KPI | 019, 072, 020 |
| 6 | After 5. Cash Register Section | 021, 022, 023, 024, 074, 076, 028, 075 |
| 7 | After 6. Top Selling | 025, 026, 073 |
| 8 | After 7. Value per Payment Method | 027 |
| 9 | After 8. Executive Summary | 029, 031, 032, 034, 035, 036, 077, 030, 033 |
| 10 | After Sales Tab | 037, 038, 043, 044, 045, 046, 049, 079, 039, 040, 041, 042, 047, 048, 050, 051, 078, 080, 081, 082 |
| 11 | After WO Info Tab | 052, 053, 054, 056, 055, 057, 083, 084 |
| 12 | After Cash Tab | 058, 059, 061, 085, 060, 086 |
| 13 | After Inventory Tab | 062, 063, 064, 065, 087, 066 |
| 14 | End | Stock Tables Check with its SSMS figures |

## Inside each block

1. Title "QA Results: section name", on a light blue background with a blue left border.
2. Table Case (38%), Result (10%), Note. The TC number links to its Test Case, followed by the title. The note gives the real values and "DB match" or the difference.
3. Figures: bold caption "Figure n: TC-xxx: what it shows", then the image (maximum width 900px).
4. Under an SSMS figure, the comparison table: Value, Dashboard, Database (from the query above), Result (green MATCH, red for a mismatch).

| Result | Colour |
|---|---|
| Pass | #107c10 |
| Fail | #d13438 |
| Blocked | #8764b8 |
| Needs Investigation | #ca5010 |
| Not Run, N/A | Grey (#605e5c, #8a8886): copy from template_qa_blocks.html |
| MATCH in comparison tables | #2e7d32 |
| Mismatch in comparison tables | #c62828 |
| Headers and borders | #0078d4 |

## Corrections for the rebuild

1. Counters come from the test points of the new Run, never from the Task text.
2. Open every image before upload, and number the figures in page order (the old numbers were out of order).
3. Every note names the new Run and date. No "19/11 run" evidence.
4. Summary, bugs and blocked lists must agree with the rows (the old summary listed 067, 071 and 075 as not run after they had run).
5. English only. Show it to the QA lead before saving.
