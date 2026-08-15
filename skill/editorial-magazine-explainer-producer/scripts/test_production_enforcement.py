#!/usr/bin/env python3
from __future__ import annotations

import copy
import hashlib
import json
import tempfile
from pathlib import Path

from validate_production_enforcement import validate_manifest


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def base_manifest(root: Path) -> dict:
    evidence = root / "evidence.txt"
    evidence.write_text("verified", encoding="utf-8")
    item = {"path": "evidence.txt", "sha256": digest(evidence)}
    return {
        "schema_version": "2.0", "mode": "production", "project_id": "test",
        "rule_layers": {
            "immutable_core": ["master_clock", "gate2_stop", "semantic_motion", "layer_exit", "caption_readability", "speech_first_bgm", "evidence_qa", "separate_publish_authorization"],
            "project_style": [], "additive_requirements": [], "revision_scope": [],
            "core_rules_cannot_be_weakened": True, "conflicts": []},
        "gate2": {"approved": True, "approval_quote": "整套通过", "approved_at": "2026-08-15T12:00:00+08:00", "render_started_after_approval": True, "evidence": [item]},
        "shots": [{
            "id": "S01",
            "semantic": {"subject": "考生", "action": "比较", "object": "项目", "turn": "校名相同规则不同", "result": "按项目判断", "audience_takeaway": "不是问学校好不好考"},
            "timing": {"sceneStart": 0, "keywordCue": 0.5, "actionCue": 0.5, "textCue": 0.6, "resultCue": 1.6, "exitCue": 2.5},
            "lifecycle": {"enter": "slide", "settle": "hold", "act_or_receive": "compare", "yield": "dim", "resolve": "focus", "exit": "wipe"},
            "layers": {"previous_exited_before_next_main": True, "lingering_layer_count": 0},
            "visual": {"giant_ordinal_only": False, "persistent_top_title": False},
            "text": {"caption": "别只问哪所学校好考", "highlight": "哪所学校好考", "highlight_mode": "semantic_keyword", "explanation_required": True, "explanation": "判断单位是具体项目", "explanation_repeats_caption": False, "form": "comparison"},
            "layout": {"main_visual_fill_ratio": 0.75, "caption_main_visual_gap_px": 240, "overlap_count": 0, "main_visual_bbox": [100, 400, 900, 1200], "explanation_bbox": [120, 280, 880, 400], "caption_bbox": [100, 1300, 980, 1480]},
            "evidence": [item]}],
        "global_visual": {"single_card_form_only": False, "persistent_top_title": False, "flow_change_count": 0, "caption_main_visual_max_gap_px": 240, "overlap_count": 0, "evidence": [item]},
        "audio": {"voice_duration_drift_ms": 0, "voice_integrated_lufs": -16, "bgm_integrated_lufs": -34.5, "bgm_normal_lufs": -33.5, "bgm_dense_lufs": -35.1, "bgm_cta_lufs": -38.2, "voice_bgm_margin_db": 18.5, "final_integrated_lufs": -16, "voice_path": "voice.wav", "bgm_ducked_path": "bgm.wav", "final_mix_path": "mix.wav", "evidence": [item]},
        "qa": {"full_decode_zero_errors": True, "continuous_ranges_reviewed": True, "full_watch_completed": True, "desktop_hash_match": True, "evidence": [item]},
        "publication": {"authorized": False, "performed": False}}


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        good = base_manifest(root)
        manifest = root / "manifest.json"
        manifest.write_text(json.dumps(good, ensure_ascii=False), encoding="utf-8")
        assert not validate_manifest(good, manifest)
        cases = [
            ("old_schema", lambda d: d.update(schema_version="1.2"), "old_schema_rejected"),
            ("no_exit", lambda d: d["shots"][0]["lifecycle"].update(exit=""), "lifecycle_exit_missing"),
            ("lingering", lambda d: d["shots"][0]["layers"].update(lingering_layer_count=1), "lingering_layer"),
            ("giant_ordinal", lambda d: d["shots"][0]["visual"].update(giant_ordinal_only=True), "giant_ordinal"),
            ("top_title", lambda d: d["global_visual"].update(persistent_top_title=True), "persistent_top_title"),
            ("missing_explanation", lambda d: d["shots"][0]["text"].update(explanation=""), "required_explanation_missing"),
            ("duplicate_explanation", lambda d: d["shots"][0]["text"].update(explanation_repeats_caption=True), "explanation_repeats_caption"),
            ("single_card", lambda d: d["global_visual"].update(single_card_form_only=True), "single_card_form"),
            ("small_visual", lambda d: d["shots"][0]["layout"].update(main_visual_fill_ratio=0.3), "main_visual_too_small"),
            ("caption_far", lambda d: d["shots"][0]["layout"].update(caption_main_visual_gap_px=600), "caption_too_far"),
            ("overlap", lambda d: d["shots"][0]["layout"].update(overlap_count=1), "overlap"),
            ("early_action", lambda d: d["shots"][0]["timing"].update(actionCue=0.1), "early_action"),
            ("flow_change", lambda d: d["global_visual"].update(flow_change_count=1), "flow_changed"),
            ("voice_drift", lambda d: d["audio"].update(voice_duration_drift_ms=25), "voice_duration_drift"),
            ("bgm_inaudible", lambda d: d["audio"].update(bgm_integrated_lufs=-50), "bgm_inaudible_or_too_loud"),
            ("segment_bgm_fail", lambda d: d["audio"].update(bgm_dense_lufs=-50), "bgm_dense_lufs_failed"),
            ("gate2_missing", lambda d: d["gate2"].update(approved=False), "gate2:not_approved"),
            ("unauthorized_publish", lambda d: d["publication"].update(performed=True), "unauthorized_publish"),
        ]
        for name, mutate, expected in cases:
            candidate = copy.deepcopy(good)
            mutate(candidate)
            errors = validate_manifest(candidate, manifest)
            assert any(expected in error for error in errors), (name, errors)
        print(f"NEGATIVE TESTS PASS {len(cases)}/18")


if __name__ == "__main__":
    main()

