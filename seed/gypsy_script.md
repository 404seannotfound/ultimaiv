# The Gypsy's Fixed Script

Original lines in the spirit of Ultima IV's character creation, written for an
otherworldly androgynous voice. These are the **fixed** beats — pre-rendered to
audio once and reused across every reading. The per-question parables are
generated live from `seed/questions.tsv` and not stored here.

Two candidates per slot where it helps. Pick or rewrite freely — these are a
first draft of the love poem.

Voice direction throughout: calm, ancient, unhurried, almost amused. She has
done this ten thousand times. She is glad you came anyway.

---

## entry / greeting (first beat after page load)

> A. *"Come in. Sit. The wind sent thee, and the wind does not waste its breath."*
>
> B. *"Closer. The candles know thee already — let me see thy face."*

## explanation (just before the first card)

> A. *"Eight cards lie between us. Eight ways a soul may stand. I shall lay them in pairs. Thou must choose. Not which is true — both are true. Only which is thine."*
>
> B. *"Look. Eight stones, eight cards, one of thee. We shall not be long. Each pair I lay, thou shalt weigh in thy breast and answer with thy heart, not thy tongue."*

## per-question framing (before each parable)

Short. Sets up the LLM-generated scenario. Reusable across all 7 questions.

> A. *"These two. Hear, and choose."*
>
> B. *"Lay thine eyes upon these. Listen."*
>
> C. *"Now this."*  ← shortest, for later questions when she trusts you

## after each answer (one beat, while a stone goes dark)

Reusable, light. Acknowledges the choice without judging it.

> A. *"So."*
>
> B. *"Mm. Set aside."*
>
> C. *"The stone remembers."*

## round transition: after round 1 (4 questions done, 4 stones dark)

> A. *"Four remain. The others are not lost — only set aside, for another to bear."*
>
> B. *"Half the deck now sleeps. Look at what is left of thee."*

## round transition: after round 2 (6 questions done, 2 stones lit)

> A. *"Two remain. Look at them. Breathe."*
>
> B. *"Only these two. The hardest pair — for both have followed thee this far."*

## before the final question (the gravity beat)

> A. *"Now the last. Choose slowly. The card thou turnest down does not vanish — it will walk a step behind thee all thy days, as faithful as the one thou turnest up."*
>
> B. *"This is the question only thou canst answer. Take thy time. I am not going anywhere."*

## closing rite (final stone lit, virtue revealed)

`{VIRTUE}` is interpolated at runtime. Pre-render one audio clip per virtue.

> A. *"{VIRTUE}. The card has chosen thee, and thou hast chosen it. Go now — the world has been waiting."*
>
> B. *"Then it is {VIRTUE} that shall lead thee. Carry it gently. It is heavier than it looks."*

## post-creation whisper (after the fade, just before the permalink reveals)

A softer voice, almost inside the player's mind rather than across the table.

> A. *"Find the king. He is looking for thee."*
>
> B. *"There is a king who has not slept for waiting. Go to him."*

---

## per-virtue closing-line variants (optional flavor)

If you want the closing rite to *also* hint at the path ahead (companion, town,
or stone), we can record eight slightly-tailored closings instead of one
template. Sketches:

- **Honesty** — *"Honesty. Moonglow's lamps burn for thee tonight. Go and see the world clearly."*
- **Compassion** — *"Compassion. There is a wounded thing on the road to Britain. Find it before another does."*
- **Valor** — *"Valor. The isles of Jhelom have a place at the table. Sit there unflinching."*
- **Justice** — *"Justice. The yews of Yew lean toward thee already. Stand straight beneath them."*
- **Sacrifice** — *"Sacrifice. There is a forge in Minoc that has been cold too long. It waits for thy hand."*
- **Honor** — *"Honor. The gates of Trinsic open for those who kneel before they enter. Kneel."*
- **Spirituality** — *"Spirituality. Skara Brae's mists know thy name already. Walk softly there."*
- **Humility** — *"Humility. New Magincia keeps no kings. Thou shalt be welcome."*

This costs eight extra recordings but turns the closing into a *handoff* rather
than a generic ceremony. Recommend turning this on — it's the moment that
matters most.
