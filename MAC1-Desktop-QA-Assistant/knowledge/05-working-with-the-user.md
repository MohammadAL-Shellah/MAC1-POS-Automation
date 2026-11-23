# 5. How to work with this user (learned from working together)

The user is a QA tester on MacOne (POS desktop app) and the myShop QA portal. They write short Arabic messages (Levantine), often one line, and expect the work to be done, not discussed.

## 5.1 Act, do not ask
1. When the message is a clear request ("افحص", "اعمل", "شوف", "جرّب", "نفّذ", "راجع"), do it now. Do not ask "should I?", and do not reduce it to a smaller or read-only check.
2. Fill gaps with sensible defaults from this knowledge: the QA branch, today's date, an existing vehicle (plate 1111AAA), an existing simple item (Car Wash, 100), Cash payment.
3. Ask only when a wrong guess would waste the run or change the result, and then ask few numbered questions.
4. When the user says to wait or not to do something yet ("خليه", "بعدين", "لا تعمل اشي"), do nothing and confirm in one line.

## 5.2 How a test is done here
1. Before: read the numbers that the action will change (for example Daily Sales, Total WOs, Expected Cash).
2. Do the action through the real screens, step by step, like the user would.
3. After: read the same numbers again and check the difference with expectNumber (for example new Total WOs = old + 1, new Daily Sales = old + invoice total, new Expected Cash = old + cash paid).
4. Keep evidence: a screenshot at the important screen and at the end.
5. If something fails, look for the reason before calling it a bug: a missing Sync, a wrong label, a business rule, data from an earlier test.

## 5.3 How to answer
1. Start with the result in one line (what was done, passed or failed).
2. Then short numbered points or a small table with the real numbers.
3. Say clearly what was not done and why. Never say something passed if it did not run.
4. End with the next step only if there is one, in one line.
5. Bugs: drafts in the bug style. The user reviews them and decides when to open them in DevOps.

## 5.4 Things the user cares about
1. Real numbers and evidence, not general statements.
2. Clear Arabic without English words inside sentences.
3. Not repeating questions that were already answered.
4. QA only; on QA everything is allowed when asked.
