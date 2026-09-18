///|
const PRESET_COUNT : Int = 3

///|
const MIN_RADIUS : Int = 12

///|
const MAX_RADIUS : Int = 34

///|
const MICROS_PER_SECOND : Int64 = 1_000_000L

///|
priv struct BreatherApp {
  canvas : @graphics.Canvas
  mut preset : Int
  mut running : Bool
  mut phase : Int
  mut phase_elapsed_us : Int64
  mut last_now_us : Int64?
}

///|
fn BreatherApp::BreatherApp() -> BreatherApp {
  {
    canvas: @graphics.Canvas::logical(),
    preset: 0,
    running: false,
    phase: 0,
    phase_elapsed_us: 0L,
    last_now_us: None,
  }
}

///|
fn preset_name(preset : Int) -> String {
  match preset {
    0 => "BOX 4-4-4-4"
    1 => "CALM 4-1-6-1"
    _ => "FOCUS 5-2-5-2"
  }
}

///|
fn phase_name(phase : Int) -> String {
  match phase {
    0 => "INHALE"
    1 => "HOLD"
    2 => "EXHALE"
    _ => "HOLD"
  }
}

///|
fn phase_seconds(preset : Int, phase : Int) -> Int {
  match (preset, phase) {
    (0, _) => 4
    (1, 0) => 4
    (1, 1) => 1
    (1, 2) => 6
    (1, _) => 1
    (2, 0) => 5
    (2, 1) => 2
    (2, 2) => 5
    _ => 2
  }
}

///|
fn phase_duration_us(preset : Int, phase : Int) -> Int64 {
  phase_seconds(preset, phase).to_int64() * MICROS_PER_SECOND
}

///|
fn orb_radius(preset : Int, phase : Int, elapsed_us : Int64) -> Int {
  let duration = phase_duration_us(preset, phase)
  let span = MAX_RADIUS - MIN_RADIUS
  let progress = if duration <= 0L {
    1000L
  } else {
    let raw = elapsed_us * 1000L / duration
    if raw < 0L {
      0L
    } else if raw > 1000L {
      1000L
    } else {
      raw
    }
  }
  match phase {
    0 => MIN_RADIUS + (span.to_int64() * progress / 1000L).to_int()
    1 => MAX_RADIUS
    2 => MAX_RADIUS - (span.to_int64() * progress / 1000L).to_int()
    _ => MIN_RADIUS
  }
}

///|
fn BreatherApp::reset_cycle(self : BreatherApp) -> Unit {
  self.phase = 0
  self.phase_elapsed_us = 0L
}

///|
fn BreatherApp::advance_time(self : BreatherApp, now_us : Int64) -> Unit {
  let delta_us = match self.last_now_us {
    Some(previous) => if now_us > previous { now_us - previous } else { 0L }
    None => 0L
  }
  self.last_now_us = Some(now_us)
  if !self.running || delta_us <= 0L {
    return
  }
  self.phase_elapsed_us += delta_us
  let mut duration = phase_duration_us(self.preset, self.phase)
  while self.phase_elapsed_us >= duration {
    self.phase_elapsed_us -= duration
    self.phase = (self.phase + 1) % 4
    duration = phase_duration_us(self.preset, self.phase)
  }
}

///|
fn BreatherApp::handle_button(
  self : BreatherApp,
  button : @input.Button,
  pressed : Bool,
) -> Unit {
  if !pressed {
    return
  }
  match button {
    Up => {
      self.preset = (self.preset + 1) % PRESET_COUNT
      self.reset_cycle()
    }
    Down => {
      self.preset = (self.preset + PRESET_COUNT - 1) % PRESET_COUNT
      self.reset_cycle()
    }
    Ok => self.running = !self.running
  }
}

///|
fn preset_color(preset : Int) -> @core.Color {
  match preset {
    0 => @core.Color::rgb(r=86, g=180, b=255)
    1 => @core.Color::rgb(r=96, g=224, b=166)
    _ => @core.Color::rgb(r=255, g=184, b=92)
  }
}

///|
fn draw_disc(
  canvas : @graphics.Canvas,
  cx : Int,
  cy : Int,
  radius : Int,
  color : @core.Color,
) -> Unit {
  let r2 = radius * radius
  for y in (cy - radius)..<(cy + radius + 1) {
    let dy = y - cy
    for x in (cx - radius)..<(cx + radius + 1) {
      let dx = x - cx
      if dx * dx + dy * dy <= r2 {
        canvas.pixel(x~, y~, color~)
      }
    }
  }
}

///|
fn draw_logo(canvas : @graphics.Canvas, color : @core.Color) -> Unit {
  canvas.fill_rect(x=4, y=4, w=2, h=7, color~)
  canvas.fill_rect(x=7, y=5, w=2, h=2, color~)
  canvas.fill_rect(x=7, y=8, w=4, h=2, color~)
  canvas.pixel(x=10, y=7, color~)
}

///|
fn centered_text(
  canvas : @graphics.Canvas,
  text : String,
  y : Int,
  color : @core.Color,
) -> Unit {
  let x = (canvas.width() - @graphics.text_width(text~)) / 2
  canvas.text(text~, x~, y~, color~)
}

///|
fn battery_text(battery_percent : Int?) -> String {
  match battery_percent {
    Some(percent) => "\{percent}%"
    None => "--%"
  }
}

///|
fn BreatherApp::draw(self : BreatherApp, battery_percent : Int?) -> Unit {
  let canvas = self.canvas
  let bg = @core.Color::rgb(r=8, g=12, b=20)
  let fg = @core.Color::rgb(r=232, g=240, b=248)
  let dim = @core.Color::rgb(r=120, g=136, b=150)
  let accent = preset_color(self.preset)
  canvas.clear(color=bg)

  draw_logo(canvas, accent)
  canvas.text(text="POCKET BREATHER", x=14, y=4, color=fg)
  let battery = battery_text(battery_percent)
  canvas.text(
    text=battery,
    x=116 - @graphics.text_width(text=battery),
    y=4,
    color=dim,
  )

  centered_text(canvas, preset_name(self.preset), 18, dim)
  let status = if self.running { phase_name(self.phase) } else { "READY" }
  centered_text(canvas, status, 32, fg)

  let radius = if self.running {
    orb_radius(self.preset, self.phase, self.phase_elapsed_us)
  } else {
    MIN_RADIUS
  }
  draw_disc(canvas, 60, 87, radius + 2, @core.Color::rgb(r=28, g=38, b=52))
  draw_disc(canvas, 60, 87, radius, accent)

  if self.running {
    let seconds = phase_seconds(self.preset, self.phase)
    let elapsed_s = (self.phase_elapsed_us / MICROS_PER_SECOND).to_int()
    let remaining = if seconds - elapsed_s > 0 {
      seconds - elapsed_s
    } else {
      1
    }
    centered_text(canvas, "\{remaining}", 84, bg)
  } else {
    centered_text(canvas, "OK", 84, bg)
  }

  canvas.fill_rect(
    x=12,
    y=132,
    w=96,
    h=1,
    color=@core.Color::rgb(r=32, g=46, b=60),
  )
  let duration = phase_duration_us(self.preset, self.phase)
  let progress_w = if self.running && duration > 0L {
    (96L * self.phase_elapsed_us / duration).to_int()
  } else {
    0
  }
  canvas.fill_rect(x=12, y=132, w=progress_w, h=1, color=accent)

  centered_text(canvas, "UP DOWN MODE", 142, dim)
  centered_text(
    canvas,
    if self.running {
      "OK PAUSE"
    } else {
      "OK START"
    },
    151,
    fg,
  )
}

///|
impl @application.Application for BreatherApp with fn update(
  self,
  ctx : @application.FrameContext,
) -> Unit {
  self.advance_time(ctx.now_us)
}

///|
impl @application.Application for BreatherApp with fn button(
  self,
  button : @input.Button,
  pressed : Bool,
) -> Unit {
  self.handle_button(button, pressed)
}

///|
impl @application.Application for BreatherApp with fn render(
  self,
  battery_percent : Int?,
) -> @graphics.FrameView {
  self.draw(battery_percent)
  self.canvas.frame_view()
}

///|
impl @application.Application for BreatherApp with fn audio_output(self) -> @application.AudioOutput? {
  let _ = self
  None
}

///|
pub fn passport_main() -> &@application.Application {
  BreatherApp()
}
