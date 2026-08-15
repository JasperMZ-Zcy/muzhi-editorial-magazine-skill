#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


CORE_RULES = {
    "master_clock", "gate2_stop", "semantic_motion", "layer_exit",
    "caption_readability", "speech_first_bgm", "evidence_qa",
    "separate_publish_authorization",
}
SEMANTIC_FIELDS = ("subject", "action", "object", "turn", "result", "audience_takeaway")
TIMING_FIELDS = ("sceneStart", "actionCue", "textCue", "resultCue", "exitCue")
LIFECYCLE_FIELDS = ("enter", "settle", "act_or_receive", "yield", "resolve", "exit")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def require(condition: bool, code: str, errors: list[str]) -> None:
    if not condition:
        errors.append(code)


def text_tokens(value: str) -> set[str]:
    return {token for token in value.replace("，", " ").replace("。", " ").split() if token}


def validate_evidence(items: object, base: Path, scope: str, errors: list[str]) -> None:
    require(isinstance(items, list) and len(items) > 0, f"{scope}:missing_evidence", errors)
    if not isinstance(items, list):
        return
    for index, item in enumerate(items):
        tag = f"{scope}:evidence[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{tag}:not_object")
            continue
        rel = item.get("path")
        digest = str(item.get("sha256", "")).upper()
        require(bool(rel), f"{tag}:missing_path", errors)
        require(len(digest) == 64, f"{tag}:missing_sha256", errors)
        if not rel:
            continue
        path = Path(rel)
        if not path.is_absolute():
            path = base / path
        require(path.is_file(), f"{tag}:file_missing", errors)
        if path.is_file() and len(digest) == 64:
            require(sha256(path) == digest, f"{tag}:hash_mismatch", errors)


def validate_shot(shot: dict, base: Path, errors: list[str]) -> None:
    sid = str(shot.get("id", "unknown"))
    prefix = f"shot:{sid}"
    semantic = shot.get("semantic", {})
    for field in SEMANTIC_FIELDS:
        require(bool(str(semantic.get(field, "")).strip()), f"{prefix}:semantic_{field}_missing", errors)

    timing = shot.get("timing", {})
    for field in TIMING_FIELDS:
        require(isinstance(timing.get(field), (int, float)), f"{prefix}:timing_{field}_missing", errors)
    if all(isinstance(timing.get(field), (int, float)) for field in TIMING_FIELDS):
        require(timing["sceneStart"] <= timing["actionCue"] <= timing["resultCue"] <= timing["exitCue"],
                f"{prefix}:early_action_or_invalid_order", errors)
        require(timing["textCue"] >= timing["sceneStart"], f"{prefix}:text_before_scene", errors)
        require(timing["actionCue"] >= timing.get("keywordCue", timing["actionCue"]) - 0.18,
                f"{prefix}:early_action", errors)

    lifecycle = shot.get("lifecycle", {})
    for field in LIFECYCLE_FIELDS:
        require(bool(lifecycle.get(field)), f"{prefix}:lifecycle_{field}_missing", errors)

    layers = shot.get("layers", {})
    require(layers.get("previous_exited_before_next_main") is True, f"{prefix}:previous_layer_not_exited", errors)
    require(layers.get("lingering_layer_count") == 0, f"{prefix}:lingering_layer", errors)

    visual = shot.get("visual", {})
    require(not visual.get("giant_ordinal_only", False), f"{prefix}:giant_ordinal", errors)
    require(not visual.get("persistent_top_title", False), f"{prefix}:persistent_top_title", errors)

    text = shot.get("text", {})
    if text.get("explanation_required", False):
        require(bool(str(text.get("explanation", "")).strip()), f"{prefix}:required_explanation_missing", errors)
    caption = str(text.get("caption", "")).strip()
    explanation = str(text.get("explanation", "")).strip()
    require(not text.get("explanation_repeats_caption", False), f"{prefix}:explanation_repeats_caption", errors)
    if caption and explanation:
        c, e = text_tokens(caption), text_tokens(explanation)
        if c and e:
            require(len(c & e) / max(1, len(e)) < 0.8, f"{prefix}:explanation_probably_duplicates_caption", errors)
    highlight_mode = text.get("highlight_mode")
    require(highlight_mode in {"semantic_keyword", "karaoke_character", "none"}, f"{prefix}:invalid_highlight_mode", errors)

    layout = shot.get("layout", {})
    require(float(layout.get("main_visual_fill_ratio", 0)) >= 0.60, f"{prefix}:main_visual_too_small", errors)
    require(float(layout.get("caption_main_visual_gap_px", 9999)) <= 390, f"{prefix}:caption_too_far", errors)
    require(int(layout.get("overlap_count", 1)) == 0, f"{prefix}:overlap", errors)
    for box in ("main_visual_bbox", "explanation_bbox", "caption_bbox"):
        require(isinstance(layout.get(box), list) and len(layout.get(box, [])) == 4,
                f"{prefix}:{box}_missing", errors)
    validate_evidence(shot.get("evidence"), base, prefix, errors)


def validate_manifest(data: dict, manifest_path: Path) -> list[str]:
    errors: list[str] = []
    base = manifest_path.parent
    try:
        schema = float(data.get("schema_version", 0))
    except (TypeError, ValueError):
        schema = 0
    require(schema >= 2.0, "manifest:old_schema_rejected", errors)
    require(data.get("mode") == "production", "manifest:not_production_mode", errors)

    rules = data.get("rule_layers", {})
    require(set(rules.get("immutable_core", [])) >= CORE_RULES, "rules:immutable_core_incomplete", errors)
    require(rules.get("core_rules_cannot_be_weakened") is True, "rules:core_can_be_weakened", errors)
    require(rules.get("conflicts") == [], "rules:unresolved_conflicts", errors)

    gate2 = data.get("gate2", {})
    require(gate2.get("approved") is True, "gate2:not_approved", errors)
    require(bool(str(gate2.get("approval_quote", "")).strip()), "gate2:missing_approval_quote", errors)
    require(bool(str(gate2.get("approved_at", "")).strip()), "gate2:missing_approval_time", errors)
    require(gate2.get("render_started_after_approval") is True, "gate2:render_before_approval", errors)
    validate_evidence(gate2.get("evidence"), base, "gate2", errors)

    shots = data.get("shots")
    require(isinstance(shots, list) and len(shots) > 0, "shots:empty", errors)
    if isinstance(shots, list):
        for shot in shots:
            if isinstance(shot, dict):
                validate_shot(shot, base, errors)
            else:
                errors.append("shots:not_object")

    global_visual = data.get("global_visual", {})
    require(not global_visual.get("single_card_form_only", False), "visual:single_card_form", errors)
    require(not global_visual.get("persistent_top_title", False), "visual:persistent_top_title", errors)
    require(global_visual.get("flow_change_count") == 0, "visual:flow_changed", errors)
    require(global_visual.get("overlap_count") == 0, "visual:overlap", errors)
    require(float(global_visual.get("caption_main_visual_max_gap_px", 9999)) <= 390, "visual:caption_too_far", errors)
    validate_evidence(global_visual.get("evidence"), base, "global_visual", errors)

    audio = data.get("audio", {})
    require(abs(float(audio.get("voice_duration_drift_ms", 9999))) <= 1.0, "audio:voice_duration_drift", errors)
    bgm = float(audio.get("bgm_integrated_lufs", -999))
    margin = float(audio.get("voice_bgm_margin_db", 999))
    require(-36 <= bgm <= -30, "audio:bgm_inaudible_or_too_loud", errors)
    require(14 <= margin <= 22, "audio:voice_bgm_margin_out_of_range", errors)
    for field in ("bgm_normal_lufs", "bgm_dense_lufs", "bgm_cta_lufs"):
        value = float(audio.get(field, -999))
        require(-42 <= value <= -28, f"audio:{field}_failed", errors)
    require(-18 <= float(audio.get("final_integrated_lufs", -999)) <= -14,
            "audio:final_loudness_failed", errors)
    for field in ("voice_path", "bgm_ducked_path", "final_mix_path"):
        require(bool(audio.get(field)), f"audio:{field}_missing", errors)
    validate_evidence(audio.get("evidence"), base, "audio", errors)

    qa = data.get("qa", {})
    for field in ("full_decode_zero_errors", "continuous_ranges_reviewed", "full_watch_completed", "desktop_hash_match"):
        require(qa.get(field) is True, f"qa:{field}_failed", errors)
    validate_evidence(qa.get("evidence"), base, "qa", errors)

    publication = data.get("publication", {})
    require(not (publication.get("performed") and not publication.get("authorized")),
            "publication:unauthorized_publish", errors)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the mandatory editorial production contract.")
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()
    path = args.manifest.resolve()
    if not path.is_file():
        print(f"FAIL manifest missing: {path}", file=sys.stderr)
        return 2
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    errors = validate_manifest(data, path)
    if errors:
        for error in errors:
            print(f"FAIL {error}")
        print(f"PRODUCTION GATE CLOSED ({len(errors)} failures)")
        return 1
    print("PRODUCTION ENFORCEMENT PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

