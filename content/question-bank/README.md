# Axiom Competitive Event Question Bank

## Target

Create **500 original, event-specific practice items for every supported 2026–2027 high-school HOSA and DECA event**. Do not count repeated templates, option-order permutations, or duplicate stems as distinct questions.

Each item must include stable ID and event code; event-specific topic / competency tag; difficulty (easy, medium, hard, expert); item type (multiple choice, short answer, scenario, role-play prompt, judge question, project/case prompt, or skill-check); prompt and options when applicable; correct answer / scoring rubric; explanation or evaluation criteria; source reference and verification status.

## Official scope sources

- HOSA 2026–2027 guidelines and event catalog: https://hosa.org/guidelines/
- HOSA competitive-event preparation resources: https://hosa.org/ceusefultools/
- DECA 2026–2027 high-school competitive events: https://www.deca.org/compete

Include high-school/secondary offerings. Do not silently mix collegiate or middle-school-only events into the high-school catalog. Keep recognition, academic testing, online simulations, role-play, prepared, and skill-based events explicitly typed and label items appropriately.

## Quality rules

1. Questions must be original practice content, not copied from proprietary/official competition exams.
2. Use the current event guidelines and official competency/topic lists as the authoritative scope.
3. Every factual answer needs a rationale and a source reference. If a source does not support an answer, mark it for review rather than inventing certainty.
4. Deduplicate by normalized stem and semantic similarity, not just by ID.
5. Validate answer keys, option count, schema, event coverage, and exact count before declaring an event complete.
6. Do not claim that a bank is complete until it has 500 validated items.
7. For performance events, use realistic prompts and scoring rubrics rather than forcing every item into multiple choice.
8. Track progress per event in a manifest, including drafted, reviewed, validated, and published counts.

## Suggested JSONL record

Each line is one JSON object:

    {
      "id": "hosa-biotechnology-0001",
      "organization": "HOSA",
      "event_code": "BT",
      "event_name": "Biotechnology",
      "school_division": "high-school",
      "item_type": "multiple_choice",
      "topic": "molecular biology",
      "difficulty": "medium",
      "prompt": "...",
      "options": ["...", "...", "...", "..."],
      "correct_answer": "...",
      "explanation": "...",
      "source_refs": [{"title": "...", "url": "...", "section": "..."}],
      "review_status": "draft"
    }

This file defines the production contract; it is **not itself a completed question bank**. Store generated banks in one JSONL file per event under this directory, and keep a machine-readable event manifest alongside them.
