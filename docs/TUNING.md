# Tuning inventory

All runtime fields are explicit in `core/tuning.tres`. This inventory maps them to the GDD.
Architecture/schema identities are also centralized to keep numeric literals out of core scripts.
Example save IDs/timestamps, sample tower geometry/scores, document versions, dates, SDK/build
requirements, market research and experimental metrics are not runtime tuning. Build requirements
remain in project/export/CI configuration. Existing GDD gameplay values are unchanged. Owner M1-D04 adds provisional contact
geometry/grip and analytic feel-check inputs; these are not measured feel evidence.

| Group | Field | Source | Value |
|---|---|---|---|
| Physics | `physics_tick_hz` | §4.2 | `60` |
| Physics | `physics_fixed_dt_s` | §4.2 | `0.016666666666666666` |
| Physics | `physics_max_catch_up_steps` | §4.2 | `3` |
| Physics | `physics_position_iterations` | §4.2 | `6` |
| Physics | `physics_velocity_passes` | §4.2 | `2` |
| Physics | `physics_max_bodies` | §4.2 | `30` |
| Physics | `physics_gravity_wu_s2` | §4.2 | `-28.0` |
| Physics | `physics_linear_damping` | §4.2 | `0.02` |
| Physics | `physics_angular_damping` | §4.2 | `0.8` |
| Physics | `physics_max_linear_velocity_wu_s` | §4.2 | `42.0` |
| Physics | `physics_max_angular_velocity_rad_s` | §4.2 | `24.0` |
| Physics | `physics_contact_slop_wu` | §4.2 | `0.02` |
| Physics | `physics_sleep_velocity_wu_s` | §4.2 | `0.05` |
| Physics | `physics_sleep_grounded_s` | §4.2 (legacy, not R14 predicate) | `0.6` |
| Physics | `sleep_still_displacement_wu` | owner R14 Decision2 / M1-D12 | `0.001` |
| Physics | `sleep_dwell_ticks` | owner R14 Decision2 / M1-D12 | `30` |
| Physics | `physics_max_children` | §3.1–3.5 | `2` |
| Physics | `physics_min_motors` | §3.1–3.5 | `1` |
| Physics | `physics_min_feet` | §3.1–3.5 | `1` |
| Physics | `physics_min_valid_parts` | §3.1–3.5 | `2` |
| Physics | `physics_part_budget` | §3.1–3.5 | `10` |
| Physics | `physics_post_part_budget` | §3.1–3.5 | `14` |
| Physics | `physics_limb_mass_per_wu` | §3.1–3.5 | `1.0` |
| Physics | `physics_passive_mass_per_wu` | §3.1–3.5 | `0.8` |
| Physics | `physics_motor_mass_per_wu` | §3.1–3.5 | `1.6` |
| Physics | `physics_grip_mass_per_wu` | §3.1–3.5 | `1.2` |
| Physics | `physics_spike_mass_per_wu` | §3.1–3.5 | `1.2` |
| Physics | `physics_sticky_mass_per_wu` | §3.1–3.5 | `1.3` |
| Physics | `physics_limb_lengths_wu` | §3.1–3.5 | `[0.4, 0.55, 0.7, 0.85, 1.0, 1.15, 1.3, 1.5]` |
| Physics | `physics_joint_length_wu` | §3.1–3.5 | `0.3` |
| Physics | `physics_foot_length_wu` | §3.1–3.5 | `0.25` |
| Physics | `physics_passive_limit_deg` | §3.1–3.5 | `110.0` |
| Physics | `physics_passive_stiffness` | §3.1–3.5 | `900.0` |
| Physics | `physics_rigid_compliance` | §3.1–3.5 | `0.0` |
| Physics | `physics_grip_friction` | §3.1–3.5 | `0.9` |
| Physics | `physics_foot_restitution` | §3.1–3.5 | `0.02` |
| Physics | `physics_spike_friction` | §3.1–3.5 | `1.15` |
| Physics | `physics_spike_sink_wu` | §3.1–3.5 | `0.03` |
| Physics | `physics_sticky_friction` | §3.1–3.5 | `1.4` |
| Physics | `physics_sticky_release_s` | §3.1–3.5 | `0.25` |
| Physics | `physics_angle_snap_deg` | §3.1–3.5 | `5.0` |
| Physics | `physics_quick_add_angles_deg` | §3.1–3.5 | `[0.0, -45.0, 45.0, -90.0, 90.0]` |
| Physics | `physics_undo_steps` | §3.1–3.5 | `20` |
| Physics | `physics_tall_warning_wu` | §3.1–3.5 | `3.2` |
| Physics | `physics_heavy_warning_mass` | §3.1–3.5 | `18.0` |
| Physics | `physics_warning_dismissals` | §3.1–3.5 | `2` |
| Physics | `physics_warning_suppression_days` | §3.1–3.5 | `7` |
| Physics | `physics_terrain_layer` | §4.4–4.5 | `0` |
| Physics | `physics_parts_layer` | §4.4–4.5 | `10` |
| Physics | `physics_feet_layer` | §4.4–4.5 | `11` |
| Physics | `physics_hazards_layer` | §4.4–4.5 | `20` |
| Physics | `physics_triggers_layer` | §4.4–4.5 | `21` |
| Physics | `physics_self_collision_min_levels` | §4.4–4.5 | `2` |
| Physics | `physics_sdf_cell_wu` | §4.4–4.5 | `0.25` |
| Physics | `physics_static_slip_wu_s` | §4.4–4.5 | `0.15` |
| Physics | `physics_foot_grip_bias` | §4.4–4.5 | `1.4` |
| Physics | `physics_max_constraint_angular_impulse_rad_s` | §4.4–4.5 | `6.0` |
| Physics | `physics_distance_solves_per_iteration` | §4.4–4.5 | `2` |
| Physics | `physics_limb_reset_residual_wu` | §4.4–4.5 | `0.25` |
| Physics | `physics_max_projection_wu_tick` | §4.4–4.5 | `0.4` |
| Physics | `physics_no_contact_forced_fall_s` | §4.4–4.5 | `30.0` |
| Physics | `physics_grip_assist_friction_bonus` | §11.4 | `0.35` |
| Physics | `physics_slow_motion_scale` | §11.4 | `0.85` |
| Physics | `physics_zero` | §10.5; §8.4; M0 structural identities | `0` |
| Physics | `physics_one` | §10.5; §8.4; M0 structural identities | `1` |
| Physics | `physics_save_schema` | §10.5; §8.4; M0 structural identities | `3` |
| Physics | `physics_settings_debounce_ms` | §10.5; §8.4; M0 structural identities | `250` |
| Physics | `physics_profile_debounce_ms` | §10.5; §8.4; M0 structural identities | `1000` |
| Physics | `physics_draft_autosave_s` | §10.5; §8.4; M0 structural identities | `20` |
| Physics | `physics_library_cap` | §10.5; §8.4; M0 structural identities | `30` |
| Physics | `physics_best_tower_history_cap` | §10.5; §8.4; M0 structural identities | `30` |
| Physics | `physics_starter_creature_count` | §10.5; §8.4; M0 structural identities | `12` |
| Physics | `physics_starters_per_palette` | §10.5; §8.4; M0 structural identities | `2` |
| Physics | `physics_lifecycle_resume_window_s` | §10.5; §8.4; M0 structural identities | `600` |
| Physics | `physics_codec_version` | §8.2–8.3 codec layout (not implemented) | `1` |
| Physics | `physics_codec_header_bits` | §8.2–8.3 codec layout (not implemented) | `24` |
| Physics | `physics_codec_version_bits` | §8.2–8.3 codec layout (not implemented) | `3` |
| Physics | `physics_codec_part_count_bits` | §8.2–8.3 codec layout (not implemented) | `4` |
| Physics | `physics_codec_root_bits` | §8.2–8.3 codec layout (not implemented) | `4` |
| Physics | `physics_codec_gain_bits` | §8.2–8.3 codec layout (not implemented) | `5` |
| Physics | `physics_codec_eye_bits` | §8.2–8.3 codec layout (not implemented) | `2` |
| Physics | `physics_codec_reserved_bits` | §8.2–8.3 codec layout (not implemented) | `1` |
| Physics | `physics_codec_record_bits` | §8.2–8.3 codec layout (not implemented) | `19` |
| Physics | `physics_codec_kind_bits` | §8.2–8.3 codec layout (not implemented) | `4` |
| Physics | `physics_codec_parent_bits` | §8.2–8.3 codec layout (not implemented) | `4` |
| Physics | `physics_codec_length_bits` | §8.2–8.3 codec layout (not implemented) | `3` |
| Physics | `physics_codec_angle_bits` | §8.2–8.3 codec layout (not implemented) | `4` |
| Physics | `physics_codec_channel_bits` | §8.2–8.3 codec layout (not implemented) | `1` |
| Physics | `physics_codec_colour_bits` | §8.2–8.3 codec layout (not implemented) | `3` |
| Physics | `physics_codec_crc_bits` | §8.2–8.3 codec layout (not implemented) | `8` |
| Physics | `physics_codec_crc_poly` | §8.2–8.3 codec layout (not implemented) | `7` |
| Physics | `physics_codec_crc_init` | §8.2–8.3 codec layout (not implemented) | `0` |
| Physics | `physics_codec_symbol_bits` | §8.2–8.3 codec layout (not implemented) | `5` |
| Physics | `physics_codec_gain_max` | §8.2–8.3 codec layout (not implemented) | `31` |
| Physics | `physics_codec_angle_bucket_deg` | §8.2–8.3 codec layout (not implemented) | `22.5` |
| Physics | `physics_codec_fingerprint_bits` | §8.2–8.3 codec layout (not implemented) | `40` |
| Physics | `physics_codec_fingerprint_symbols` | §8.2–8.3 codec layout (not implemented) | `8` |
| Physics | `physics_codec_group_symbols` | §8.2–8.3 codec layout (not implemented) | `4` |
| Physics | `physics_codec_root_id` | §8.2–8.3 codec layout (not implemented) | `0` |
| Physics | `physics_codec_reserved` | §8.2–8.3 codec layout (not implemented) | `0` |
| Physics | `physics_ghost_fallback_hz` | §4.6; §8.7 replay data budgets | `10` |
| Physics | `physics_ghost_max_duration_s` | §4.6; §8.7 replay data budgets | `120` |
| Physics | `physics_input_bits_per_tick` | §4.6; §8.7 replay data budgets | `2` |
| Physics | `physics_mobility_min_seeds` | §13.1; §13.3 acceptance/experiment gates | `3` |
| Physics | `physics_placement_max_taps` | §13.1; §13.3 acceptance/experiment gates | `3` |
| Physics | `physics_usability_testers` | §13.1; §13.3 acceptance/experiment gates | `5` |
| Physics | `physics_goal_correct_testers_min` | §13.1; §13.3 acceptance/experiment gates | `4` |
| Physics | `physics_goal_observation_s` | §13.1; §13.3 acceptance/experiment gates | `20` |
| Physics | `physics_first_flag_p0_budget_s` | §13.1; §13.3 acceptance/experiment gates | `60` |
| Physics | `physics_voluntary_retry_min_fraction` | §13.1; §13.3 acceptance/experiment gates | `0.6` |
| Physics | `physics_builders_min_testers` | §13.1; §13.3 acceptance/experiment gates | `3` |
| Physics | `physics_closed_test_min_users` | §13.1; §13.3 acceptance/experiment gates | `50` |
| Physics | `physics_closed_test_max_users` | §13.1; §13.3 acceptance/experiment gates | `200` |
| Physics | `physics_voluntary_session_target_min` | §13.1; §13.3 acceptance/experiment gates | `8` |
| Physics | `physics_headless_speed_multiplier` | §13.1; §13.3 acceptance/experiment gates | `10.0` |
| Physics | `physics_experiment_b_play_min` | §13.1; §13.3 acceptance/experiment gates | `10` |
| Physics | `physics_control_iterations_max` | §13.1; §13.3 acceptance/experiment gates | `2` |
| Physics | `physics_experiment_d_clips_min` | §13.1; §13.3 acceptance/experiment gates | `12` |
| Physics | `physics_experiment_d_clips_max` | §13.1; §13.3 acceptance/experiment gates | `20` |
| Physics | `physics_experiment_d_formats` | §13.1; §13.3 acceptance/experiment gates | `4` |
| Physics | `physics_first_flag_target_fraction` | §14.2–14.3 unmeasured evaluation thresholds | `0.7` |
| Physics | `physics_first_flag_kill_fraction` | §14.2–14.3 unmeasured evaluation thresholds | `0.4` |
| Physics | `physics_first_flag_target_s` | §14.2–14.3 unmeasured evaluation thresholds | `90` |
| Physics | `physics_first_flag_kill_s` | §14.2–14.3 unmeasured evaluation thresholds | `180` |
| Physics | `physics_retry_target_fraction` | §14.2–14.3 unmeasured evaluation thresholds | `0.6` |
| Physics | `physics_retry_kill_fraction` | §14.2–14.3 unmeasured evaluation thresholds | `0.35` |
| Physics | `physics_week_one_builds_min` | §14.2–14.3 unmeasured evaluation thresholds | `2` |
| Physics | `physics_share_session_target_fraction` | §14.2–14.3 unmeasured evaluation thresholds | `0.01` |
| Physics | `physics_redemptions_per_100_installs_min` | §14.2–14.3 unmeasured evaluation thresholds | `5` |
| Physics | `physics_retention_d1_target` | §14.2–14.3 unmeasured evaluation thresholds | `0.25` |
| Physics | `physics_retention_d7_target` | §14.2–14.3 unmeasured evaluation thresholds | `0.08` |
| Physics | `physics_retention_d1_kill` | §14.2–14.3 unmeasured evaluation thresholds | `0.15` |
| Physics | `physics_crash_free_target_fraction` | §14.2–14.3 unmeasured evaluation thresholds | `0.995` |
| Physics | `physics_crash_free_kill_fraction` | §14.2–14.3 unmeasured evaluation thresholds | `0.98` |
| Physics | `physics_session_target_min` | §14.2–14.3 unmeasured evaluation thresholds | `6` |
| Physics | `physics_session_kill_min` | §14.2–14.3 unmeasured evaluation thresholds | `3` |
| Physics | `physics_disconfirm_play_min` | §14.2–14.3 unmeasured evaluation thresholds | `5` |
| Physics | `physics_disconfirm_share_sessions` | §14.2–14.3 unmeasured evaluation thresholds | `200` |
| Physics | `physics_disconfirm_clip_s` | §14.2–14.3 unmeasured evaluation thresholds | `15` |
| Physics | `physics_determinism_ticks` | §10.6; §13.1 validation budgets | `10000` |
| Physics | `physics_determinism_local_runs` | §10.6; §13.1 validation budgets | `100` |
| Physics | `physics_determinism_replay_s` | §10.6; §13.1 validation budgets | `60` |
| Physics | `physics_determinism_devices` | §10.6; §13.1 validation budgets | `5` |
| Physics | `physics_soak_runs` | §10.6; §13.1 validation budgets | `200` |
| Physics | `physics_input_visual_budget_ms` | §10.6; §13.1 validation budgets | `50` |
| Physics | `physics_motor_return_target_ms` | §10.6; §13.1 validation budgets | `260` |
| Physics | `physics_motor_return_tolerance_ms` | §10.6; §13.1 validation budgets | `40` |
| Physics | `physics_settle_budget_s` | §10.6; §13.1 validation budgets | `4` |
| Physics | `physics_limb_stretch_max_wu` | §10.6; §13.1 validation budgets | `0.05` |
| Physics | `physics_impact_tests` | §10.6; §13.1 validation budgets | `500` |
| Physics | `physics_creature_mobility_cases` | §10.6; §13.1 validation budgets | `200` |
| Physics | `physics_creature_mobility_seeds` | §10.6; §13.1 validation budgets | `3` |
| Physics | `physics_creature_mobility_min_wu` | §10.6; §13.1 validation budgets | `1.0` |
| Physics | `physics_creature_mobility_window_s` | §10.6; §13.1 validation budgets | `20` |
| Physics | `physics_codec_test_vectors_min` | §10.6; §13.1 validation budgets | `12` |
| Physics | `physics_codec_mutation_symbols_max` | §10.6; §13.1 validation budgets | `3` |
| Physics | `physics_codec_mutation_cases` | §10.6; §13.1 validation budgets | `10000` |
| Physics | `physics_process_kill_trials` | §10.6; §13.1 validation budgets | `30` |
| Motors | `motors_contraction_deg` | §3.2; §3.4 | `62.0` |
| Motors | `motors_joint_stiffness` | §3.2; §3.4 | `2400.0` |
| Motors | `motors_joint_damping` | §3.2; §3.4 | `55.0` |
| Motors | `motors_max_torque` | §3.2; §3.4 | `1800.0` |
| Motors | `motors_limit_min_deg` | §3.2; §3.4 | `-140.0` |
| Motors | `motors_limit_max_deg` | §3.2; §3.4 | `40.0` |
| Motors | `motors_gain_min` | §3.2; §3.4 | `0.0` |
| Motors | `motors_gain_max` | §3.2; §3.4 | `1.0` |
| Motors | `motors_gain_default` | §3.2; §3.4 | `0.7` |
| Motors | `motors_gain_ui_step` | §3.2; §3.4 | `0.01` |
| Motors | `motors_input_left_mask` | §3.2; §3.4 | `1` |
| Motors | `motors_input_right_mask` | §3.2; §3.4 | `2` |
| Motors | `motors_input_both_mask` | §3.2; §3.4 | `3` |
| Motors | `motors_input_released_mask` | §3.2; §3.4 | `0` |
| Camera | `camera_deadzone_height_fraction` | §4.8 | `0.18` |
| Camera | `camera_vertical_follow_weight` | §4.8 | `1.0` |
| Camera | `camera_horizontal_follow_weight` | §4.8 | `0.35` |
| Camera | `camera_lookahead_height_fraction` | §4.8 | `0.25` |
| Camera | `camera_default_zoom` | §4.8 | `1.0` |
| Camera | `camera_airborne_zoom_section_4_8` | §4.8 | `0.72` |
| Camera | `camera_airborne_delay_s` | §4.8 | `0.7` |
| Camera | `camera_zoom_lerp_per_s` | §4.8 | `3.0` |
| Camera | `camera_summit_margin_wu` | §4.8 | `2.0` |
| Camera | `camera_shake_enabled` | §4.8 | `False` |
| Camera | `camera_shake_max_px` | §4.8 | `4.0` |
| Camera | `camera_shake_frequency_upper_hz` | §4.8 | `3.0` |
| Camera | `camera_airborne_zoom_section_2_3` | §2.3 S03 (conflicts with §4.8; blocked) | `0.75` |
| Camera | `camera_reverse_speed_limit_px_s` | §2.3 S03 (conflicts with §4.8; blocked) | `220.0` |
| Camera | `camera_viewport_width_px` | §10.4 | `1080` |
| Camera | `camera_viewport_height_px` | §10.4 | `2340` |
| Camera | `camera_min_content_scale` | §10.4 | `0.85` |
| Camera | `camera_target_fps` | §10.4 | `60` |
| Camera | `camera_frame_p95_budget_ms` | §10.4 | `16.6` |
| Camera | `camera_physics_budget_ms` | §10.4 | `3.0` |
| Camera | `camera_physics_budget_constraints` | §10.4 | `120` |
| Camera | `camera_draw_calls_budget` | §10.4 | `45` |
| Camera | `camera_texture_memory_budget_mb` | §10.4 | `96` |
| Camera | `camera_apk_download_budget_mb` | §10.4 | `70` |
| Camera | `camera_cold_start_budget_ms` | §10.4 | `3000` |
| Camera | `camera_warm_resume_budget_ms` | §10.4 | `250` |
| Camera | `camera_battery_budget_fraction` | §10.4 | `0.08` |
| Camera | `camera_battery_window_min` | §10.4 | `10` |
| Camera | `camera_rss_budget_mb` | §10.4 | `320` |
| Camera | `camera_card_radius_min_px` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `24` |
| Camera | `camera_card_radius_max_px` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `32` |
| Camera | `camera_shadow_y_px` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `8` |
| Camera | `camera_shadow_blur_px` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `24` |
| Camera | `camera_shadow_alpha` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `0.25` |
| Camera | `camera_pause_scrim_alpha` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `0.65` |
| Camera | `camera_toast_height_px` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `40` |
| Camera | `camera_toast_duration_s` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `2.2` |
| Camera | `camera_toast_queue_max` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `1` |
| Camera | `camera_spinner_timeout_s` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `3.0` |
| Camera | `camera_currency_animation_ms` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `600` |
| Camera | `camera_control_feedback_ms` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `80` |
| Camera | `camera_pressed_scale` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `0.96` |
| Camera | `camera_transition_ms` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `260` |
| Camera | `camera_pad_tip_lifetime_runs` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `3` |
| Camera | `camera_pause_audio_scale` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `0.2` |
| Camera | `camera_restart_confirm_after_s` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `60` |
| Camera | `camera_list_skeleton_max_ms` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `300` |
| Camera | `camera_preview_idle_s` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `3.0` |
| Camera | `camera_preview_pages` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `3` |
| Camera | `camera_practice_cached_days` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `3` |
| Camera | `camera_reset_confirm_changed_parts` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `3` |
| Camera | `camera_splash_target_ms` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `900` |
| Camera | `camera_splash_cap_ms` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `1500` |
| Camera | `camera_splash_tilt_px` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `6` |
| Camera | `camera_warm_start_ms` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `200` |
| Camera | `camera_touch_region_width_fraction` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `0.45` |
| Camera | `camera_touch_region_height_fraction` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `0.24` |
| Camera | `camera_share_card_width_px` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `1080` |
| Camera | `camera_share_card_height_px` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `1350` |
| Camera | `camera_share_card_render_scale` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `3` |
| Camera | `camera_rate_prompt_completed_runs` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `5` |
| Camera | `camera_touch_min_dp` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `48` |
| Camera | `camera_text_scale_min` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `1.0` |
| Camera | `camera_text_scale_max` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `1.3` |
| Camera | `camera_max_flashes_hz` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `3.0` |
| Camera | `camera_motor_glyph_alpha` | §2.1; §9.1; §9.4–9.5 UI tokens/policies | `0.4` |
| Camera | `camera_music_default_gain` | §11.1–11.3 audio/haptics | `0.7` |
| Camera | `camera_sfx_default_gain` | §11.1–11.3 audio/haptics | `0.8` |
| Camera | `camera_motor_pitch_semitones` | §11.1–11.3 audio/haptics | `2` |
| Camera | `camera_motor_pitch_contraction_step` | §11.1–11.3 audio/haptics | `0.1` |
| Camera | `camera_foot_sfx_variants` | §11.1–11.3 audio/haptics | `4` |
| Camera | `camera_fall_sfx_s` | §11.1–11.3 audio/haptics | `0.6` |
| Camera | `camera_flag_fanfare_s` | §11.1–11.3 audio/haptics | `1.5` |
| Camera | `camera_music_loops` | §11.1–11.3 audio/haptics | `3` |
| Camera | `camera_music_bpm_min` | §11.1–11.3 audio/haptics | `90` |
| Camera | `camera_music_bpm_max` | §11.1–11.3 audio/haptics | `110` |
| Camera | `camera_music_loop_max_mb` | §11.1–11.3 audio/haptics | `1.2` |
| Camera | `camera_audio_voice_pool` | §11.1–11.3 audio/haptics | `12` |
| Camera | `camera_same_sfx_max_instances` | §11.1–11.3 audio/haptics | `4` |
| Camera | `camera_music_duck_db` | §11.1–11.3 audio/haptics | `-6.0` |
| Camera | `camera_haptic_press_ms` | §11.1–11.3 audio/haptics | `8` |
| Camera | `camera_haptic_landing_ms` | §11.1–11.3 audio/haptics | `12` |
| Camera | `camera_haptic_fall_ms` | §11.1–11.3 audio/haptics | `[40, 20]` |
| Camera | `camera_haptic_flag_ms` | §11.1–11.3 audio/haptics | `[25, 25, 25]` |
| Camera | `camera_haptic_medal_ms` | §11.1–11.3 audio/haptics | `[15, 15]` |
| Camera | `camera_android_min_sdk` | §10.1–10.2 build contract (mirrored by project/export config) | `26` |
| Camera | `camera_android_target_sdk` | §10.1–10.2 build contract (mirrored by project/export config) | `36` |
| Camera | `camera_android_native_page_kb` | §10.1–10.2 build contract (mirrored by project/export config) | `16` |
| Camera | `camera_engine_major` | §10.1–10.2 build contract (mirrored by project/export config) | `4` |
| Camera | `camera_engine_minor` | §10.1–10.2 build contract (mirrored by project/export config) | `7` |
| Camera | `camera_engine_patch` | §10.1–10.2 build contract (mirrored by project/export config) | `2` |
| Fall | `fall_checkpoint_trigger_width_wu` | §4.7; §5.2–5.6 | `3.0` |
| Fall | `fall_checkpoint_drop_wu` | §4.7; §5.2–5.6 | `5.0` |
| Fall | `fall_below_checkpoint_airborne_s` | §4.7; §5.2–5.6 | `2.5` |
| Fall | `fall_fade_out_ms` | §4.7; §5.2–5.6 | `180` |
| Fall | `fall_fade_in_ms` | §4.7; §5.2–5.6 | `180` |
| Fall | `fall_input_grace_s` | §4.7; §5.2–5.6 | `0.35` |
| Fall | `fall_restart_budget_ms` | §4.7; §5.2–5.6 | `800` |
| Fall | `fall_stuck_grounded_s` | §4.7; §5.2–5.6 | `8.0` |
| Fall | `fall_stuck_progress_wu` | §4.7; §5.2–5.6 | `0.5` |
| Fall | `fall_stuck_restart_hint_delay_s` | §4.7; §5.2–5.6 | `4.0` |
| Fall | `fall_soft_lock_s` | §4.7; §5.2–5.6 | `12.0` |
| Fall | `fall_bounds_half_width_wu` | §4.7; §5.2–5.6 | `9.0` |
| Fall | `fall_ceiling_margin_wu` | §4.7; §5.2–5.6 | `6.0` |
| Fall | `fall_overlay_fade_ms` | §4.7; §5.2–5.6 | `260` |
| Fall | `fall_overlay_black_alpha` | §4.7; §5.2–5.6 | `0.55` |
| Fall | `fall_vignette_width_px` | §4.7; §5.2–5.6 | `1` |
| Fall | `fall_hazard_flash_max_hz` | §4.7; §5.2–5.6 | `1.0` |
| Fall | `fall_emergency_restart_hold_s` | §4.7; §5.2–5.6 | `1.5` |
| Fall | `fall_restart_undo_s` | §4.7; §5.2–5.6 | `3.0` |
| Fall | `fall_invalid_state_box_wu` | §4.7; §5.2–5.6 | `200.0` |
| Fall | `fall_invalid_state_resume_s` | §4.7; §5.2–5.6 | `0.4` |
| Fall | `fall_invalid_state_max_recoveries` | §4.7; §5.2–5.6 | `3` |
| Fall | `fall_respawn_eye_look_s` | §4.7; §5.2–5.6 | `1.0` |
| Score | `score_run_timeout_s` | §7.2–7.4 | `900` |
| Score | `score_score_floor` | §7.2–7.4 | `0` |
| Score | `score_fall_penalty` | §7.2–7.4 | `150` |
| Score | `score_second_penalty` | §7.2–7.4 | `10` |
| Score | `score_coin_pickup_value` | §7.2–7.4 | `50` |
| Score | `score_daily_budget_min` | §7.2–7.4 | `3000` |
| Score | `score_daily_budget_max` | §7.2–7.4 | `6000` |
| Score | `score_v1_tower_coins` | §7.2–7.4 | `0` |
| Score | `score_gold_time_multiplier` | §7.2–7.4 | `1.0` |
| Score | `score_gold_max_falls` | §7.2–7.4 | `1` |
| Score | `score_silver_time_multiplier` | §7.2–7.4 | `1.25` |
| Score | `score_silver_max_falls` | §7.2–7.4 | `3` |
| Score | `score_bronze_time_multiplier` | §7.2–7.4 | `1.6` |
| Score | `score_bronze_alternative_min_falls` | §7.2–7.4 | `1` |
| Economy | `economy_starting_coins` | §7.5–7.7 | `0` |
| Economy | `economy_first_daily_coins` | §7.5–7.7 | `50` |
| Economy | `economy_first_daily_cap` | §7.5–7.7 | `1` |
| Economy | `economy_repeat_daily_coins` | §7.5–7.7 | `10` |
| Economy | `economy_repeat_daily_cap` | §7.5–7.7 | `5` |
| Economy | `economy_gold_coins` | §7.5–7.7 | `40` |
| Economy | `economy_silver_coins` | §7.5–7.7 | `25` |
| Economy | `economy_bronze_coins` | §7.5–7.7 | `15` |
| Economy | `economy_medal_award_cap_per_tower` | §7.5–7.7 | `1` |
| Economy | `economy_pb_coins` | §7.5–7.7 | `15` |
| Economy | `economy_pb_daily_cap` | §7.5–7.7 | `3` |
| Economy | `economy_share_coins` | §7.5–7.7 | `5` |
| Economy | `economy_share_daily_cap` | §7.5–7.7 | `1` |
| Economy | `economy_rewarded_ad_coins` | §7.5–7.7 | `20` |
| Economy | `economy_rewarded_ad_daily_cap` | §7.5–7.7 | `3` |
| Economy | `economy_classic_price` | §7.5–7.7 | `0` |
| Economy | `economy_forest_price` | §7.5–7.7 | `200` |
| Economy | `economy_desert_price` | §7.5–7.7 | `200` |
| Economy | `economy_neon_price` | §7.5–7.7 | `300` |
| Economy | `economy_ice_price` | §7.5–7.7 | `300` |
| Economy | `economy_space_price` | §7.5–7.7 | `300` |
| Economy | `economy_palette_part_colours` | §7.5–7.7 | `6` |
| Economy | `economy_budget_unlock_slots` | §7.5–7.7 | `1` |
| Economy | `economy_share_ad_cooldown_s` | §8.9; §10.8 | `60` |
| Economy | `economy_ad_timeout_s` | §8.9; §10.8 | `8.0` |
| Economy | `economy_entitlement_grant_retries` | §8.9; §10.8 | `3` |
| Economy | `economy_offline_default` | §8.9; §10.8 | `True` |
| Economy | `economy_vibration_default` | §8.9; §10.8 | `True` |
| Economy | `economy_tips_default` | §8.9; §10.8 | `True` |
| Generator | `generator_gen_version` | §6.1–6.5 | `1` |
| Generator | `generator_chunk_width_wu` | §6.1–6.5 | `7.2` |
| Generator | `generator_chunk_height_wu` | §6.1–6.5 | `8.0` |
| Generator | `generator_obstacles_min` | §6.1–6.5 | `1` |
| Generator | `generator_obstacles_max` | §6.1–6.5 | `4` |
| Generator | `generator_stitch_tolerance_min_wu` | §6.1–6.5 | `0.0` |
| Generator | `generator_stitch_tolerance_max_wu` | §6.1–6.5 | `1.0` |
| Generator | `generator_ledge_min_wu` | §6.1–6.5 | `0.4` |
| Generator | `generator_ledge_max_wu` | §6.1–6.5 | `1.0` |
| Generator | `generator_slope_angles_deg` | §6.1–6.5 | `[15.0, 30.0, 45.0]` |
| Generator | `generator_gap_min_wu` | §6.1–6.5 | `0.8` |
| Generator | `generator_gap_max_wu` | §6.1–6.5 | `2.4` |
| Generator | `generator_stairs_min_steps` | §6.1–6.5 | `2` |
| Generator | `generator_stairs_max_steps` | §6.1–6.5 | `5` |
| Generator | `generator_chimney_max_width_wu` | §6.1–6.5 | `1.6` |
| Generator | `generator_p0_obstacle_kinds` | §6.1–6.5 | `6` |
| Generator | `generator_ice_friction` | §6.1–6.5 | `0.15` |
| Generator | `generator_wind_min_g` | §6.1–6.5 | `0.6` |
| Generator | `generator_wind_max_g` | §6.1–6.5 | `1.6` |
| Generator | `generator_moving_platform_min_period_s` | §6.1–6.5 | `3.0` |
| Generator | `generator_moving_platform_max_period_s` | §6.1–6.5 | `6.0` |
| Generator | `generator_crumble_delay_s` | §6.1–6.5 | `0.6` |
| Generator | `generator_conveyor_speed_wu_s` | §6.1–6.5 | `1.2` |
| Generator | `generator_baked_days` | §6.1–6.5 | `90` |
| Generator | `generator_cached_days` | §6.1–6.5 | `30` |
| Generator | `generator_day_epoch` | §6.1–6.5 | `2026-01-01` |
| Generator | `generator_difficulty_min` | §6.1–6.5 | `1` |
| Generator | `generator_difficulty_max` | §6.1–6.5 | `10` |
| Generator | `generator_campaign_difficulty_step` | §6.1–6.5 | `0.55` |
| Generator | `generator_campaign_pitch_reset_delta` | §6.1–6.5 | `-2` |
| Generator | `generator_daily_start_difficulty` | §6.1–6.5 | `2` |
| Generator | `generator_daily_peak_difficulty` | §6.1–6.5 | `9` |
| Generator | `generator_daily_peak_height_min` | §6.1–6.5 | `0.75` |
| Generator | `generator_daily_peak_height_max` | §6.1–6.5 | `0.85` |
| Generator | `generator_p0_chunks` | §6.1–6.5 | `8` |
| Generator | `generator_p0_checkpoints` | §6.1–6.5 | `2` |
| Generator | `generator_p0_target_clear_s` | §6.1–6.5 | `55` |
| Generator | `generator_daily_chunks_min` | §6.1–6.5 | `14` |
| Generator | `generator_daily_chunks_max` | §6.1–6.5 | `20` |
| Generator | `generator_daily_checkpoints_min` | §6.1–6.5 | `4` |
| Generator | `generator_daily_checkpoints_max` | §6.1–6.5 | `5` |
| Generator | `generator_daily_clear_min_s` | §6.1–6.5 | `90` |
| Generator | `generator_daily_clear_max_s` | §6.1–6.5 | `150` |
| Generator | `generator_pitch_chunks_min` | §6.1–6.5 | `3` |
| Generator | `generator_pitch_chunks_max` | §6.1–6.5 | `5` |
| Generator | `generator_reach_capsule_wu` | §6.1–6.5 | `2.2` |
| Generator | `generator_reference_parts` | §6.1–6.5 | `8` |
| Generator | `generator_reference_time_multiplier` | §6.1–6.5 | `3.0` |
| Generator | `generator_reroll_attempts` | §6.1–6.5 | `40` |

## Owner M1-D04 additions (provisional, not retuned)

| Group | Field | Source | Value |
|---|---|---|---|
| Owner geometry / feel | `physics_limb_collision_radius_wu` | owner M1-D04 | `0.065` |
| Owner geometry / feel | `physics_passive_collision_radius_wu` | owner M1-D04 | `0.085` |
| Owner geometry / feel | `physics_motor_collision_radius_wu` | owner M1-D04 | `0.095` |
| Owner geometry / feel | `physics_foot_collision_radius_wu` | owner M1-D04 | `0.050` |
| Owner geometry / feel | `physics_head_collision_radius_wu` | owner M1-D04 | `0.100` |
| Owner geometry / feel | `art_limb_visual_radius_wu` | owner M1-D04 | `0.065` |
| Owner geometry / feel | `art_passive_visual_radius_wu` | owner M1-D04 | `0.105` |
| Owner geometry / feel | `art_motor_visual_radius_wu` | owner M1-D04 | `0.120` |
| Owner geometry / feel | `art_foot_visual_radius_wu` | owner M1-D04 | `0.065` |
| Owner geometry / feel | `art_head_visual_radius_wu` | owner M1-D04 | `0.135` |
| Owner geometry / feel | `physics_head_mass_per_wu` | owner M1-D04 | `2.2` |
| Owner geometry / feel | `physics_head_length_wu` | owner M1-D04 | `0.35` |
| Owner geometry / feel | `physics_grip_normal_force_ratio` | owner M1-D04 | `0.40` |
| Owner geometry / feel | `physics_grip_normal_force_floor` | owner M1-D04 | `5.0` |
| Owner geometry / feel | `physics_d10_bend_margin_wu` | owner M1-D04 | `0.06` |
| Owner geometry / feel | `feel_readability_px_per_wu` | owner M1-D04 | `150.0` |
| Owner geometry / feel | `feel_min_collision_diameter_px` | owner M1-D04 | `15.0` |
| Owner geometry / feel | `feel_min_head_collision_diameter_px` | owner M1-D04 | `30.0` |
| Owner geometry / feel | `feel_limb_aspect_ratio_min` | owner M1-D04 | `3.0` |
| Owner geometry / feel | `feel_limb_aspect_ratio_max` | owner M1-D04 | `12.0` |
| Owner geometry / feel | `feel_static_scene_ticks` | owner M1-D04 | `600` |
| Owner geometry / feel | `feel_tutorial_runs` | owner M1-D04 | `10` |
| Owner geometry / feel | `feel_tutorial_successes_min` | owner M1-D04 | `6` |
| Owner geometry / feel | `feel_tutorial_successes_max` | owner M1-D04 | `8` |

Head mass is derived (2.2 ×0.35 =0.77), never an independently authored mass.
Visual fields are art-only, never physics inputs. FA readability scale150px/WU
is not a camera choice; M1-B04 remains unresolved. Existing foot bias1.4 and static
slip0.15 are unchanged. Any retuning requires owner approval with measurements.
