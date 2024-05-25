# Experimental stimuli

Files:
* `full_sentence_hand_written_stimuli.jsonl`: Stimuli for single noun experiment (Exp. 1 in paper)
* `2_noun_full_sentence_hand_written_stimuli.jsonl`: Stimuli for 2 noun experiment (Exp. 2 in paper)

Structure of items:

`full_sentence_hand_written_stimuli.json`:
```json

{
  "id": "<ITEM IDENTFIER>",
  "i_sentence": "<SENTENCE AND REFERENTIAL CONTINUATION>", 
  "s_sentence": "<SENTENCE AND NON-EFERENTIAL CONTINUATION>", 
  "type": "<ITEM TYPE>"
}

```

`2_noun_full_sentence_hand_written_stimuli.jsonl`:
```json
{
{
  "id": "<ITEM IDENTFIER>",
  "exp_sentence": "<SENTENCE AND EXPECTED CONTINUATION>", 
  "unexp_sentence": "<SENTENCE AND UNEXPECTED CONTINUATION>",
  "prompt": "<SENTENCE>", 
  "exp_continuation": "<EXPECTED CONTINUATION>", 
  "unexp_continuation": "<UNEXPECTED CONTINUATION>", 
  "type": "<ITEM TYPE>", 
  "order": "<ORDER OF NOUNS (1 or 2)>"
}
```
