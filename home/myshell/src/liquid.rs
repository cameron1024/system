//! The liquid shape: a body hanging from the top edge of the screen, joined by concave flares.
//! Each side is a concave quarter-ellipse (the flare) then a convex one (the rounded bottom), so
//! it can range from a cosine-like bump to a flat-bottomed body. Pure geometry, so the shape can
//! be checked for every animation frame without rendering.

use gpui::FillOptions;
use gpui::FillRule;
use gpui::Path;
use gpui::PathBuilder;
use gpui::PathStyle;
use gpui::Pixels;
use gpui::point;
use gpui::px;

/// Radius of the concave flares where the liquid meets the screen edge, at rest.
pub const FLARE: f32 = 14.;
/// Cubic approximation of a quarter circle.
const K: f32 = 0.552;

type P = (f32, f32);

#[derive(Clone, Copy, Debug)]
enum Segment {
    Line(P),
    Cubic(P, P, P),
}

#[derive(Debug)]
pub struct Outline {
    start: P,
    segments: Vec<Segment>,
}

/// Each side: a concave flare, a straight side, then a convex rounded bottom.
pub struct Corners {
    pub flare_x: f32,
    pub flare_y: f32,
    pub radius_x: f32,
    pub radius_y: f32,
    /// The side's horizontal run per unit of drop (0 is vertical). Flat, bump-like shapes need
    /// a sloped side: a vertical one would bend sharply where the flare meets the bottom.
    pub slope: f32,
}

/// A body whose sides start at `x0` and `x1`, hanging `bottom` below the screen edge. The flares
/// extend outside the sides; the sides slope inwards, then round into the bottom. Callers keep
/// `flare_y + radius_y <= bottom`, and the sides' inward run plus `radius_x` within half the
/// width.
pub fn outline(x0: f32, x1: f32, bottom: f32, corners: Corners) -> Option<Outline> {
    if bottom <= 0. {
        return None;
    }
    let Corners {
        flare_x: fx,
        flare_y: fy,
        radius_x: rx,
        radius_y: ry,
        slope: s,
    } = corners;
    let side_end = bottom - ry;
    // Where the straight side meets the rounded bottom, inset by the side's slope.
    let inset = s * (side_end - fy);

    let mut segments = Vec::with_capacity(10);
    let mut push = |segment| segments.push(segment);
    // Left: the flare curves from the screen edge down into the side...
    push(Segment::Line((x0 - fx, 0.)));
    push(Segment::Cubic(
        (x0 - fx + fx * K, 0.),
        (x0 - s * fy * K, fy * (1. - K)),
        (x0, fy),
    ));
    // ...which then rounds into the bottom.
    let (side_x, bottom_x) = (x0 + inset, x0 + inset + rx);
    push(Segment::Line((side_x, side_end)));
    push(Segment::Cubic(
        (side_x + s * ry * K, side_end + ry * K),
        (bottom_x - rx * K, bottom),
        (bottom_x, bottom),
    ));
    // Right: mirrored.
    let (side_x, bottom_x) = (x1 - inset, x1 - inset - rx);
    push(Segment::Line((bottom_x, bottom)));
    push(Segment::Cubic(
        (bottom_x + rx * K, bottom),
        (side_x - s * ry * K, side_end + ry * K),
        (side_x, side_end),
    ));
    push(Segment::Line((x1, fy)));
    push(Segment::Cubic(
        (x1 + s * fy * K, fy * (1. - K)),
        (x1 + fx - fx * K, 0.),
        (x1 + fx, 0.),
    ));
    push(Segment::Line((x1 + fx, -1.)));
    Some(Outline {
        start: (x0 - fx, -1.),
        segments,
    })
}

/// Fills the concave corner where a horizontal edge (to the left, at `y`) meets a vertical edge
/// (below, at `x`), with the same curve as the flares. It overlaps both bodies slightly, so the
/// union has no seams.
pub fn fillet(x: f32, y: f32, radius: f32) -> Outline {
    let r = radius;
    Outline {
        start: (x - r, y - 1.),
        segments: vec![
            Segment::Line((x - r, y)),
            Segment::Cubic((x - r + r * K, y), (x, y + r * (1. - K)), (x, y + r)),
            Segment::Line((x + 1., y + r)),
            Segment::Line((x + 1., y - 1.)),
        ],
    }
}

/// One fill for all outlines. With the non-zero rule, overlapping shapes (e.g. adjacent peeks)
/// merge into one body, rather than translucent overlaps painting darker.
pub fn path(outlines: &[Outline]) -> Option<Path<Pixels>> {
    let p = |(x, y): P| point(px(x), px(y));
    let mut path = PathBuilder::fill().with_style(PathStyle::Fill(
        FillOptions::default().with_fill_rule(FillRule::NonZero),
    ));
    for outline in outlines {
        path.move_to(p(outline.start));
        for segment in &outline.segments {
            match *segment {
                Segment::Line(to) => path.line_to(p(to)),
                Segment::Cubic(a, b, to) => path.cubic_bezier_to(p(to), p(a), p(b)),
            }
        }
        path.close();
    }
    path.build().ok()
}

/// The outlines' combined horizontal extent on each visible 1px row, merging rows with equal
/// extents. Each side of an outline is monotonic in y, so a row crosses it exactly twice.
pub fn rows(outlines: &[Outline]) -> Vec<(i32, i32, i32, i32)> {
    let mut rects: Vec<(i32, i32, i32, i32)> = Vec::new();
    for outline in outlines {
        let points = outline.points(0.5);
        let bottom = points
            .iter()
            .fold(0., |bottom: f32, point| bottom.max(point.1));
        for row in 0..bottom.ceil() as i32 {
            let y = row as f32 + 0.5;
            let crossings = points.windows(2).filter_map(|w| {
                let (a, b) = (w[0], w[1]);
                ((a.1 <= y) != (b.1 <= y)).then(|| a.0 + (b.0 - a.0) * (y - a.1) / (b.1 - a.1))
            });
            let Some((left, right)) = crossings.fold(None, |range: Option<(f32, f32)>, x| {
                Some(range.map_or((x, x), |(left, right)| (left.min(x), right.max(x))))
            }) else {
                continue;
            };
            let (x, width) = (left.round() as i32, (right.round() - left.round()) as i32);
            match rects.last_mut() {
                Some(last) if (last.0, last.2) == (x, width) && last.1 + last.3 == row => {
                    last.3 += 1;
                }
                _ => rects.push((x, row, width, 1)),
            }
        }
    }
    rects
}

impl Outline {
    /// Points along the outline, roughly `step` apart on curves.
    fn points(&self, step: f32) -> Vec<P> {
        let mut points = vec![self.start];
        let mut from = self.start;
        for segment in &self.segments {
            match *segment {
                Segment::Line(to) => {
                    let n = (distance(from, to) / step).ceil().max(1.) as usize;
                    points.extend((1..=n).map(|i| lerp(from, to, i as f32 / n as f32)));
                    from = to;
                }
                Segment::Cubic(a, b, to) => {
                    let length = distance(from, a) + distance(a, b) + distance(b, to);
                    let n = (length / step).ceil().max(1.) as usize;
                    points.extend((1..=n).map(|i| cubic(from, a, b, to, i as f32 / n as f32)));
                    from = to;
                }
            }
        }
        points
    }
}

fn distance(a: P, b: P) -> f32 {
    (b.0 - a.0).hypot(b.1 - a.1)
}

fn lerp(a: P, b: P, t: f32) -> P {
    (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t)
}

fn cubic(p0: P, p1: P, p2: P, p3: P, t: f32) -> P {
    let u = 1. - t;
    let [w0, w1, w2, w3] = [u * u * u, 3. * u * u * t, 3. * u * t * t, t * t * t];
    (
        w0 * p0.0 + w1 * p1.0 + w2 * p2.0 + w3 * p3.0,
        w0 * p0.1 + w1 * p1.1 + w2 * p2.1 + w3 * p3.1,
    )
}

#[cfg(test)]
pub mod tests {
    use super::*;

    /// Places where the visible outline (below the screen edge) turns more than `max_degrees`
    /// within `window` pixels of its length, as (degrees, location). A smooth curve of radius r
    /// turns window / r radians, so this flags anything tighter than an antialiased pixel or two.
    pub fn sharp_corners(outline: &Outline, window: f32, max_degrees: f32) -> Vec<(f32, P)> {
        // Resample by arc length, so tight bends aren't hidden by the curve's parameterisation.
        let dense = outline.points(0.02);
        let step = 0.1;
        let mut points = vec![dense[0]];
        for &point in &dense[1..] {
            if distance(*points.last().unwrap(), point) >= step {
                points.push(point);
            }
        }
        let turns: Vec<f32> = points
            .windows(3)
            .map(|w| {
                let (a, b) = (
                    (w[1].0 - w[0].0, w[1].1 - w[0].1),
                    (w[2].0 - w[1].0, w[2].1 - w[1].1),
                );
                (a.0 * b.1 - a.1 * b.0)
                    .atan2(a.0 * b.0 + a.1 * b.1)
                    .to_degrees()
            })
            .collect();
        let span = (window / step) as usize;
        let mut corners = Vec::new();
        for (i, window) in turns.windows(span).enumerate() {
            let turn = window.iter().sum::<f32>().abs();
            let location = points[i + 1 + span / 2];
            // The screen edge hides anything at or above y = 0.
            if turn > max_degrees && location.1 > 0.5 {
                corners.push((turn, location));
            }
        }
        corners
    }
}
