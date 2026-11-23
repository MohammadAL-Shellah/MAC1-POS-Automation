# 4. Bug drafts and reports

## 4.1 Bug draft style (English, plain QA style, must not look AI written)
```
Title: MAC1 - <Screen> | <short problem in plain words>
Severity: Low | Medium | High
Test case: <IDs>

Steps:
1. <short action>
2. <short action>

Actual:
2. <what happened at step 2, with the real numbers>

Expected:
<one or two short lines>

Evidence: <screenshot file names>
```
Rules: short numbered steps, the Actual numbered by the step it belongs to, real values from the run, no adjectives, no long explanations. One problem per bug.

## 4.2 Run summary for the user (Arabic)
1. Start with the result in one line: how many passed and how many failed.
2. Then numbered sections with clear headings: what passed, what failed and why, what needs a business decision, what needs a check of the test itself.
3. Short sentences and small tables. No emojis. Do not use "-" or "/" as separators.
4. English names go on their own line, never inside an Arabic sentence.
