///|
test "preset durations are stable" {
  inspect(phase_seconds(0, 0), content="4")
  inspect(phase_seconds(0, 3), content="4")
  inspect(phase_seconds(1, 0), content="4")
  inspect(phase_seconds(1, 1), content="1")
  inspect(phase_seconds(1, 2), content="6")
  inspect(phase_seconds(2, 0), content="5")
  inspect(phase_seconds(2, 1), content="2")
}

///|
test "orb follows inhale hold exhale hold" {
  inspect(orb_radius(0, 0, 0L), content="12")
  inspect(orb_radius(0, 0, 2_000_000L), content="23")
  inspect(orb_radius(0, 0, 4_000_000L), content="34")
  inspect(orb_radius(0, 1, 2_000_000L), content="34")
  inspect(orb_radius(0, 2, 0L), content="34")
  inspect(orb_radius(0, 2, 4_000_000L), content="12")
  inspect(orb_radius(0, 3, 2_000_000L), content="12")
}

///|
test "paused time does not advance the cycle" {
  let app = BreatherApp::new()
  app.advance_time(10_000_000L)
  app.advance_time(12_000_000L)
  inspect(app.phase_elapsed_us, content="0")
  app.handle_button(Ok, true)
  app.advance_time(14_000_000L)
  inspect(app.phase_elapsed_us, content="2000000")
  app.handle_button(Ok, true)
  app.advance_time(20_000_000L)
  inspect(app.phase_elapsed_us, content="2000000")
}

///|
test "box cycle advances through phases" {
  let app = BreatherApp::new()
  app.handle_button(Ok, true)
  app.advance_time(0L)
  app.advance_time(4_000_000L)
  inspect(app.phase, content="1")
  app.advance_time(8_000_000L)
  inspect(app.phase, content="2")
  app.advance_time(16_000_000L)
  inspect(app.phase, content="0")
}

///|
test "mode buttons wrap and reset cycle" {
  let app = BreatherApp::new()
  app.handle_button(Down, true)
  inspect(app.preset, content="2")
  app.phase = 2
  app.phase_elapsed_us = 123L
  app.handle_button(Up, true)
  inspect(app.preset, content="0")
  inspect(app.phase, content="0")
  inspect(app.phase_elapsed_us, content="0")
}
