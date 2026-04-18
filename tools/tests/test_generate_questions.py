from tools.generate_questions.generate_questions import (
    deduplicate,
    extract_json,
    select_categories,
)


def test_deduplicate():
    qs = [
        {"question": "Q1", "answer": "A1"},
        {"question": "q1", "answer": "A1"},  # Case insensitive duplicate
        {"question": "Q2", "answer": "A2"},
    ]
    unique = deduplicate(qs)
    assert len(unique) == 2
    assert unique[0]["question"] == "Q1"
    assert unique[1]["question"] == "Q2"


def test_extract_json_bare_array():
    text = '```json\n[{"q": "1"}]\n```'
    data = extract_json(text)
    assert data == [{"q": "1"}]


def test_extract_json_wrapper():
    text = '{"questions": [{"q": "1"}]}'
    data = extract_json(text)
    assert data == [{"q": "1"}]


def test_select_categories():
    all_cats = [
        {"slug": "cat1", "title": "Category One"},
        {"slug": "cat2", "title": "Category Two"},
        {"slug": "emoji", "title": "Emoji Fun"},
    ]

    # All
    assert select_categories(all_cats, "all") == all_cats

    # Indices
    assert select_categories(all_cats, "1,3") == [all_cats[0], all_cats[2]]

    # Range
    assert select_categories(all_cats, "1-2") == [all_cats[0], all_cats[1]]

    # Partial title
    assert select_categories(all_cats, "emoji") == [all_cats[2]]

    # Slug
    assert select_categories(all_cats, "cat1") == [all_cats[0]]
