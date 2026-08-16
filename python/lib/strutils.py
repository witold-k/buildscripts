def strip_code_fences(text) -> str:
    if text is None:
        return ""

    text = text.strip()

    if "```" not in text:
        return text.strip()

    lines = text.splitlines(keepends=True)
    out = []
    inside = False

    for line in lines:
        if not inside and line.startswith("```"):
            inside = True
            continue
        if inside and line.startswith("```"):
            inside = False
            continue
        if inside:
            out.append(line)

    return "".join(out).strip()

