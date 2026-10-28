class_name Tuning
extends Resource
## GDD §10.9. Values live ONLY in tuning.tres; see docs/TUNING.md.

@export_group("Physics")
## GDD §4.2
@export var physics_tick_hz: int
## GDD §4.2
@export var physics_fixed_dt_s: float
## GDD §4.2
@export var physics_max_catch_up_steps: int
## GDD §4.2
@export var physics_position_iterations: int
## GDD §4.2
@export var physics_velocity_passes: int
## GDD §4.2
@export var physics_max_bodies: int
## GDD §4.2
@export var physics_gravity_wu_s2: float
## GDD §4.2
@export var physics_linear_damping: float
## GDD §4.2
@export var physics_angular_damping: float
## GDD §4.2
@export var physics_max_linear_velocity_wu_s: float
## GDD §4.2
@export var physics_max_angular_velocity_rad_s: float
## GDD §4.2
@export var physics_contact_slop_wu: float
## GDD §4.2
@export var physics_sleep_velocity_wu_s: float
## GDD §4.2
@export var physics_sleep_grounded_s: float
## GDD §3.1–3.5
@export var physics_max_children: int
## GDD §3.1–3.5
@export var physics_min_motors: int
## GDD §3.1–3.5
@export var physics_min_feet: int
## GDD §3.1–3.5
@export var physics_min_valid_parts: int
## GDD §3.1–3.5
@export var physics_part_budget: int
## GDD §3.1–3.5
@export var physics_post_part_budget: int
## GDD §3.1–3.5
@export var physics_limb_mass_per_wu: float
## GDD §3.1–3.5
@export var physics_passive_mass_per_wu: float
## GDD §3.1–3.5
@export var physics_motor_mass_per_wu: float
## GDD §3.1–3.5
@export var physics_grip_mass_per_wu: float
## GDD §3.1–3.5
@export var physics_spike_mass_per_wu: float
## GDD §3.1–3.5
@export var physics_sticky_mass_per_wu: float
## GDD §3.1–3.5
@export var physics_limb_lengths_wu: PackedFloat64Array
## GDD §3.1–3.5
@export var physics_joint_length_wu: float
## GDD §3.1–3.5
@export var physics_foot_length_wu: float
## GDD §3.1–3.5
@export var physics_passive_limit_deg: float
## GDD §3.1–3.5
@export var physics_passive_stiffness: float
## GDD §3.1–3.5
@export var physics_rigid_compliance: float
## GDD §3.1–3.5
@export var physics_grip_friction: float
## GDD §3.1–3.5
@export var physics_foot_restitution: float
## GDD §3.1–3.5
@export var physics_spike_friction: float
## GDD §3.1–3.5
@export var physics_spike_sink_wu: float
## GDD §3.1–3.5
@export var physics_sticky_friction: float
## GDD §3.1–3.5
@export var physics_sticky_release_s: float
## GDD §3.1–3.5
@export var physics_angle_snap_deg: float
## GDD §3.1–3.5
@export var physics_quick_add_angles_deg: PackedFloat64Array
## GDD §3.1–3.5
@export var physics_undo_steps: int
## GDD §3.1–3.5
@export var physics_tall_warning_wu: float
## GDD §3.1–3.5
@export var physics_heavy_warning_mass: float
## GDD §3.1–3.5
@export var physics_warning_dismissals: int
## GDD §3.1–3.5
@export var physics_warning_suppression_days: int
## GDD §4.4–4.5
@export var physics_terrain_layer: int
## GDD §4.4–4.5
@export var physics_parts_layer: int
## GDD §4.4–4.5
@export var physics_feet_layer: int
## GDD §4.4–4.5
@export var physics_hazards_layer: int
## GDD §4.4–4.5
@export var physics_triggers_layer: int
## GDD §4.4–4.5
@export var physics_self_collision_min_levels: int
## GDD §4.4–4.5
@export var physics_sdf_cell_wu: float
## GDD §4.4–4.5
@export var physics_static_slip_wu_s: float
## GDD §4.4–4.5
@export var physics_foot_grip_bias: float
## GDD §4.4–4.5
@export var physics_max_constraint_angular_impulse_rad_s: float
## GDD §4.4–4.5
@export var physics_distance_solves_per_iteration: int
## GDD §4.4–4.5
@export var physics_limb_reset_residual_wu: float
## GDD §4.4–4.5
@export var physics_max_projection_wu_tick: float
## GDD §4.4–4.5
@export var physics_no_contact_forced_fall_s: float
## GDD §11.4
@export var physics_grip_assist_friction_bonus: float
## GDD §11.4
@export var physics_slow_motion_scale: float
## GDD §10.5; §8.4; M0 structural identities
@export var physics_zero: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_one: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_save_schema: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_settings_debounce_ms: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_profile_debounce_ms: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_draft_autosave_s: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_library_cap: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_best_tower_history_cap: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_starter_creature_count: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_starters_per_palette: int
## GDD §10.5; §8.4; M0 structural identities
@export var physics_lifecycle_resume_window_s: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_version: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_header_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_version_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_part_count_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_root_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_gain_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_eye_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_reserved_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_record_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_kind_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_parent_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_length_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_angle_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_channel_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_colour_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_crc_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_crc_poly: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_crc_init: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_symbol_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_gain_max: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_angle_bucket_deg: float
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_fingerprint_bits: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_fingerprint_symbols: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_group_symbols: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_root_id: int
## GDD §8.2–8.3 codec layout (not implemented)
@export var physics_codec_reserved: int
## GDD §4.6; §8.7 replay data budgets
@export var physics_ghost_fallback_hz: int
## GDD §4.6; §8.7 replay data budgets
@export var physics_ghost_max_duration_s: int
## GDD §4.6; §8.7 replay data budgets
@export var physics_input_bits_per_tick: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_mobility_min_seeds: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_placement_max_taps: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_usability_testers: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_goal_correct_testers_min: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_goal_observation_s: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_first_flag_p0_budget_s: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_voluntary_retry_min_fraction: float
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_builders_min_testers: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_closed_test_min_users: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_closed_test_max_users: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_voluntary_session_target_min: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_headless_speed_multiplier: float
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_experiment_b_play_min: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_control_iterations_max: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_experiment_d_clips_min: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_experiment_d_clips_max: int
## GDD §13.1; §13.3 acceptance/experiment gates
@export var physics_experiment_d_formats: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_first_flag_target_fraction: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_first_flag_kill_fraction: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_first_flag_target_s: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_first_flag_kill_s: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_retry_target_fraction: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_retry_kill_fraction: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_week_one_builds_min: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_share_session_target_fraction: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_redemptions_per_100_installs_min: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_retention_d1_target: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_retention_d7_target: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_retention_d1_kill: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_crash_free_target_fraction: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_crash_free_kill_fraction: float
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_session_target_min: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_session_kill_min: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_disconfirm_play_min: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_disconfirm_share_sessions: int
## GDD §14.2–14.3 unmeasured evaluation thresholds
@export var physics_disconfirm_clip_s: int
## GDD §10.6; §13.1 validation budgets
@export var physics_determinism_ticks: int
## GDD §10.6; §13.1 validation budgets
@export var physics_determinism_local_runs: int
## GDD §10.6; §13.1 validation budgets
@export var physics_determinism_replay_s: int
## GDD §10.6; §13.1 validation budgets
@export var physics_determinism_devices: int
## GDD §10.6; §13.1 validation budgets
@export var physics_soak_runs: int
## GDD §10.6; §13.1 validation budgets
@export var physics_input_visual_budget_ms: int
## GDD §10.6; §13.1 validation budgets
@export var physics_motor_return_target_ms: int
## GDD §10.6; §13.1 validation budgets
@export var physics_motor_return_tolerance_ms: int
## GDD §10.6; §13.1 validation budgets
@export var physics_settle_budget_s: int
## GDD §10.6; §13.1 validation budgets
@export var physics_limb_stretch_max_wu: float
## GDD §10.6; §13.1 validation budgets
@export var physics_impact_tests: int
## GDD §10.6; §13.1 validation budgets
@export var physics_creature_mobility_cases: int
## GDD §10.6; §13.1 validation budgets
@export var physics_creature_mobility_seeds: int
## GDD §10.6; §13.1 validation budgets
@export var physics_creature_mobility_min_wu: float
## GDD §10.6; §13.1 validation budgets
@export var physics_creature_mobility_window_s: int
## GDD §10.6; §13.1 validation budgets
@export var physics_codec_test_vectors_min: int
## GDD §10.6; §13.1 validation budgets
@export var physics_codec_mutation_symbols_max: int
## GDD §10.6; §13.1 validation budgets
@export var physics_codec_mutation_cases: int
## GDD §10.6; §13.1 validation budgets
@export var physics_process_kill_trials: int

@export_group("Motors")
## GDD §3.2; §3.4
@export var motors_contraction_deg: float
## GDD §3.2; §3.4
@export var motors_joint_stiffness: float
## GDD §3.2; §3.4
@export var motors_joint_damping: float
## GDD §3.2; §3.4
@export var motors_max_torque: float
## GDD §3.2; §3.4
@export var motors_limit_min_deg: float
## GDD §3.2; §3.4
@export var motors_limit_max_deg: float
## GDD §3.2; §3.4
@export var motors_gain_min: float
## GDD §3.2; §3.4
@export var motors_gain_max: float
## GDD §3.2; §3.4
@export var motors_gain_default: float
## GDD §3.2; §3.4
@export var motors_gain_ui_step: float
## GDD §3.2; §3.4
@export var motors_input_left_mask: int
## GDD §3.2; §3.4
@export var motors_input_right_mask: int
## GDD §3.2; §3.4
@export var motors_input_both_mask: int
## GDD §3.2; §3.4
@export var motors_input_released_mask: int

@export_group("Camera")
## GDD §4.8
@export var camera_deadzone_height_fraction: float
## GDD §4.8
@export var camera_vertical_follow_weight: float
## GDD §4.8
@export var camera_horizontal_follow_weight: float
## GDD §4.8
@export var camera_lookahead_height_fraction: float
## GDD §4.8
@export var camera_default_zoom: float
## GDD §4.8
@export var camera_airborne_zoom_section_4_8: float
## GDD §4.8
@export var camera_airborne_delay_s: float
## GDD §4.8
@export var camera_zoom_lerp_per_s: float
## GDD §4.8
@export var camera_summit_margin_wu: float
## GDD §4.8
@export var camera_shake_enabled: bool
## GDD §4.8
@export var camera_shake_max_px: float
## GDD §4.8
@export var camera_shake_frequency_upper_hz: float
## GDD §2.3 S03 (conflicts with §4.8; blocked)
@export var camera_airborne_zoom_section_2_3: float
## GDD §2.3 S03 (conflicts with §4.8; blocked)
@export var camera_reverse_speed_limit_px_s: float
## GDD §10.4
@export var camera_viewport_width_px: int
## GDD §10.4
@export var camera_viewport_height_px: int
## GDD §10.4
@export var camera_min_content_scale: float
## GDD §10.4
@export var camera_target_fps: int
## GDD §10.4
@export var camera_frame_p95_budget_ms: float
## GDD §10.4
@export var camera_physics_budget_ms: float
## GDD §10.4
@export var camera_physics_budget_constraints: int
## GDD §10.4
@export var camera_draw_calls_budget: int
## GDD §10.4
@export var camera_texture_memory_budget_mb: int
## GDD §10.4
@export var camera_apk_download_budget_mb: int
## GDD §10.4
@export var camera_cold_start_budget_ms: int
## GDD §10.4
@export var camera_warm_resume_budget_ms: int
## GDD §10.4
@export var camera_battery_budget_fraction: float
## GDD §10.4
@export var camera_battery_window_min: int
## GDD §10.4
@export var camera_rss_budget_mb: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_card_radius_min_px: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_card_radius_max_px: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_shadow_y_px: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_shadow_blur_px: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_shadow_alpha: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_pause_scrim_alpha: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_toast_height_px: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_toast_duration_s: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_toast_queue_max: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_spinner_timeout_s: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_currency_animation_ms: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_control_feedback_ms: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_pressed_scale: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_transition_ms: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_pad_tip_lifetime_runs: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_pause_audio_scale: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_restart_confirm_after_s: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_list_skeleton_max_ms: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_preview_idle_s: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_preview_pages: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_practice_cached_days: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_reset_confirm_changed_parts: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_splash_target_ms: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_splash_cap_ms: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_splash_tilt_px: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_warm_start_ms: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_touch_region_width_fraction: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_touch_region_height_fraction: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_share_card_width_px: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_share_card_height_px: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_share_card_render_scale: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_rate_prompt_completed_runs: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_touch_min_dp: int
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_text_scale_min: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_text_scale_max: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_max_flashes_hz: float
## GDD §2.1; §9.1; §9.4–9.5 UI tokens/policies
@export var camera_motor_glyph_alpha: float
## GDD §11.1–11.3 audio/haptics
@export var camera_music_default_gain: float
## GDD §11.1–11.3 audio/haptics
@export var camera_sfx_default_gain: float
## GDD §11.1–11.3 audio/haptics
@export var camera_motor_pitch_semitones: int
## GDD §11.1–11.3 audio/haptics
@export var camera_motor_pitch_contraction_step: float
## GDD §11.1–11.3 audio/haptics
@export var camera_foot_sfx_variants: int
## GDD §11.1–11.3 audio/haptics
@export var camera_fall_sfx_s: float
## GDD §11.1–11.3 audio/haptics
@export var camera_flag_fanfare_s: float
## GDD §11.1–11.3 audio/haptics
@export var camera_music_loops: int
## GDD §11.1–11.3 audio/haptics
@export var camera_music_bpm_min: int
## GDD §11.1–11.3 audio/haptics
@export var camera_music_bpm_max: int
## GDD §11.1–11.3 audio/haptics
@export var camera_music_loop_max_mb: float
## GDD §11.1–11.3 audio/haptics
@export var camera_audio_voice_pool: int
## GDD §11.1–11.3 audio/haptics
@export var camera_same_sfx_max_instances: int
## GDD §11.1–11.3 audio/haptics
@export var camera_music_duck_db: float
## GDD §11.1–11.3 audio/haptics
@export var camera_haptic_press_ms: int
## GDD §11.1–11.3 audio/haptics
@export var camera_haptic_landing_ms: int
## GDD §11.1–11.3 audio/haptics
@export var camera_haptic_fall_ms: PackedInt32Array
## GDD §11.1–11.3 audio/haptics
@export var camera_haptic_flag_ms: PackedInt32Array
## GDD §11.1–11.3 audio/haptics
@export var camera_haptic_medal_ms: PackedInt32Array
## GDD §10.1–10.2 build contract (mirrored by project/export config)
@export var camera_android_min_sdk: int
## GDD §10.1–10.2 build contract (mirrored by project/export config)
@export var camera_android_target_sdk: int
## GDD §10.1–10.2 build contract (mirrored by project/export config)
@export var camera_android_native_page_kb: int
## GDD §10.1–10.2 build contract (mirrored by project/export config)
@export var camera_engine_major: int
## GDD §10.1–10.2 build contract (mirrored by project/export config)
@export var camera_engine_minor: int
## GDD §10.1–10.2 build contract (mirrored by project/export config)
@export var camera_engine_patch: int

@export_group("Fall")
## GDD §4.7; §5.2–5.6
@export var fall_checkpoint_trigger_width_wu: float
## GDD §4.7; §5.2–5.6
@export var fall_checkpoint_drop_wu: float
## GDD §4.7; §5.2–5.6
@export var fall_below_checkpoint_airborne_s: float
## GDD §4.7; §5.2–5.6
@export var fall_fade_out_ms: int
## GDD §4.7; §5.2–5.6
@export var fall_fade_in_ms: int
## GDD §4.7; §5.2–5.6
@export var fall_input_grace_s: float
## GDD §4.7; §5.2–5.6
@export var fall_restart_budget_ms: int
## GDD §4.7; §5.2–5.6
@export var fall_stuck_grounded_s: float
## GDD §4.7; §5.2–5.6
@export var fall_stuck_progress_wu: float
## GDD §4.7; §5.2–5.6
@export var fall_stuck_restart_hint_delay_s: float
## GDD §4.7; §5.2–5.6
@export var fall_soft_lock_s: float
## GDD §4.7; §5.2–5.6
@export var fall_bounds_half_width_wu: float
## GDD §4.7; §5.2–5.6
@export var fall_ceiling_margin_wu: float
## GDD §4.7; §5.2–5.6
@export var fall_overlay_fade_ms: int
## GDD §4.7; §5.2–5.6
@export var fall_overlay_black_alpha: float
## GDD §4.7; §5.2–5.6
@export var fall_vignette_width_px: int
## GDD §4.7; §5.2–5.6
@export var fall_hazard_flash_max_hz: float
## GDD §4.7; §5.2–5.6
@export var fall_emergency_restart_hold_s: float
## GDD §4.7; §5.2–5.6
@export var fall_restart_undo_s: float
## GDD §4.7; §5.2–5.6
@export var fall_invalid_state_box_wu: float
## GDD §4.7; §5.2–5.6
@export var fall_invalid_state_resume_s: float
## GDD §4.7; §5.2–5.6
@export var fall_invalid_state_max_recoveries: int
## GDD §4.7; §5.2–5.6
@export var fall_respawn_eye_look_s: float

@export_group("Score")
## GDD §7.2–7.4
@export var score_run_timeout_s: int
## GDD §7.2–7.4
@export var score_score_floor: int
## GDD §7.2–7.4
@export var score_fall_penalty: int
## GDD §7.2–7.4
@export var score_second_penalty: int
## GDD §7.2–7.4
@export var score_coin_pickup_value: int
## GDD §7.2–7.4
@export var score_daily_budget_min: int
## GDD §7.2–7.4
@export var score_daily_budget_max: int
## GDD §7.2–7.4
@export var score_v1_tower_coins: int
## GDD §7.2–7.4
@export var score_gold_time_multiplier: float
## GDD §7.2–7.4
@export var score_gold_max_falls: int
## GDD §7.2–7.4
@export var score_silver_time_multiplier: float
## GDD §7.2–7.4
@export var score_silver_max_falls: int
## GDD §7.2–7.4
@export var score_bronze_time_multiplier: float
## GDD §7.2–7.4
@export var score_bronze_alternative_min_falls: int

@export_group("Economy")
## GDD §7.5–7.7
@export var economy_starting_coins: int
## GDD §7.5–7.7
@export var economy_first_daily_coins: int
## GDD §7.5–7.7
@export var economy_first_daily_cap: int
## GDD §7.5–7.7
@export var economy_repeat_daily_coins: int
## GDD §7.5–7.7
@export var economy_repeat_daily_cap: int
## GDD §7.5–7.7
@export var economy_gold_coins: int
## GDD §7.5–7.7
@export var economy_silver_coins: int
## GDD §7.5–7.7
@export var economy_bronze_coins: int
## GDD §7.5–7.7
@export var economy_medal_award_cap_per_tower: int
## GDD §7.5–7.7
@export var economy_pb_coins: int
## GDD §7.5–7.7
@export var economy_pb_daily_cap: int
## GDD §7.5–7.7
@export var economy_share_coins: int
## GDD §7.5–7.7
@export var economy_share_daily_cap: int
## GDD §7.5–7.7
@export var economy_rewarded_ad_coins: int
## GDD §7.5–7.7
@export var economy_rewarded_ad_daily_cap: int
## GDD §7.5–7.7
@export var economy_classic_price: int
## GDD §7.5–7.7
@export var economy_forest_price: int
## GDD §7.5–7.7
@export var economy_desert_price: int
## GDD §7.5–7.7
@export var economy_neon_price: int
## GDD §7.5–7.7
@export var economy_ice_price: int
## GDD §7.5–7.7
@export var economy_space_price: int
## GDD §7.5–7.7
@export var economy_palette_part_colours: int
## GDD §7.5–7.7
@export var economy_budget_unlock_slots: int
## GDD §8.9; §10.8
@export var economy_share_ad_cooldown_s: int
## GDD §8.9; §10.8
@export var economy_ad_timeout_s: float
## GDD §8.9; §10.8
@export var economy_entitlement_grant_retries: int
## GDD §8.9; §10.8
@export var economy_offline_default: bool
## GDD §8.9; §10.8
@export var economy_vibration_default: bool
## GDD §8.9; §10.8
@export var economy_tips_default: bool

@export_group("Generator")
## GDD §6.1–6.5
@export var generator_gen_version: int
## GDD §6.1–6.5
@export var generator_chunk_width_wu: float
## GDD §6.1–6.5
@export var generator_chunk_height_wu: float
## GDD §6.1–6.5
@export var generator_obstacles_min: int
## GDD §6.1–6.5
@export var generator_obstacles_max: int
## GDD §6.1–6.5
@export var generator_stitch_tolerance_min_wu: float
## GDD §6.1–6.5
@export var generator_stitch_tolerance_max_wu: float
## GDD §6.1–6.5
@export var generator_ledge_min_wu: float
## GDD §6.1–6.5
@export var generator_ledge_max_wu: float
## GDD §6.1–6.5
@export var generator_slope_angles_deg: PackedFloat64Array
## GDD §6.1–6.5
@export var generator_gap_min_wu: float
## GDD §6.1–6.5
@export var generator_gap_max_wu: float
## GDD §6.1–6.5
@export var generator_stairs_min_steps: int
## GDD §6.1–6.5
@export var generator_stairs_max_steps: int
## GDD §6.1–6.5
@export var generator_chimney_max_width_wu: float
## GDD §6.1–6.5
@export var generator_p0_obstacle_kinds: int
## GDD §6.1–6.5
@export var generator_ice_friction: float
## GDD §6.1–6.5
@export var generator_wind_min_g: float
## GDD §6.1–6.5
@export var generator_wind_max_g: float
## GDD §6.1–6.5
@export var generator_moving_platform_min_period_s: float
## GDD §6.1–6.5
@export var generator_moving_platform_max_period_s: float
## GDD §6.1–6.5
@export var generator_crumble_delay_s: float
## GDD §6.1–6.5
@export var generator_conveyor_speed_wu_s: float
## GDD §6.1–6.5
@export var generator_baked_days: int
## GDD §6.1–6.5
@export var generator_cached_days: int
## GDD §6.1–6.5
@export var generator_day_epoch: String
## GDD §6.1–6.5
@export var generator_difficulty_min: int
## GDD §6.1–6.5
@export var generator_difficulty_max: int
## GDD §6.1–6.5
@export var generator_campaign_difficulty_step: float
## GDD §6.1–6.5
@export var generator_campaign_pitch_reset_delta: int
## GDD §6.1–6.5
@export var generator_daily_start_difficulty: int
## GDD §6.1–6.5
@export var generator_daily_peak_difficulty: int
## GDD §6.1–6.5
@export var generator_daily_peak_height_min: float
## GDD §6.1–6.5
@export var generator_daily_peak_height_max: float
## GDD §6.1–6.5
@export var generator_p0_chunks: int
## GDD §6.1–6.5
@export var generator_p0_checkpoints: int
## GDD §6.1–6.5
@export var generator_p0_target_clear_s: int
## GDD §6.1–6.5
@export var generator_daily_chunks_min: int
## GDD §6.1–6.5
@export var generator_daily_chunks_max: int
## GDD §6.1–6.5
@export var generator_daily_checkpoints_min: int
## GDD §6.1–6.5
@export var generator_daily_checkpoints_max: int
## GDD §6.1–6.5
@export var generator_daily_clear_min_s: int
## GDD §6.1–6.5
@export var generator_daily_clear_max_s: int
## GDD §6.1–6.5
@export var generator_pitch_chunks_min: int
## GDD §6.1–6.5
@export var generator_pitch_chunks_max: int
## GDD §6.1–6.5
@export var generator_reach_capsule_wu: float
## GDD §6.1–6.5
@export var generator_reference_parts: int
## GDD §6.1–6.5
@export var generator_reference_time_multiplier: float
## GDD §6.1–6.5
@export var generator_reroll_attempts: int
