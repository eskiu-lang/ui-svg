<p align="center">
  <img src="https://raw.githubusercontent.com/eskiu-lang/eskiu/main/assets/logo.png" alt="Eskiu, a kitten with a ball of yarn" width="140">
</p>

<h2 align="center">svg</h2>
<p align="center">Vector drawings from SVG text, for Eskiu ui apps.</p>
<p align="center"><sub>Part of the <a href="https://github.com/eskiu-lang">Eskiu</a> project</sub></p>

---

```eskiu
import <ui>;
import <svg>;

const string kHeart = "<svg viewBox=\"0 0 24 24\"><path fill=\"currentColor\" d=\"M12 21 3 12a5 5 0 0 1 9-7 5 5 0 0 1 9 7z\"/></svg>";

void Like(bool liked) {
    Svg(Style{width: 24, height: 24, color: liked ? rgb(230, 57, 70) : rgb(140, 140, 140)}, kHeart);
}
```

`Svg(style, svg)` draws an SVG document's text in the box `style` gives it, scaled to fit and
centered (`xMidYMid meet`). With only a width or a height, the other follows the viewBox's
proportions. `currentColor` is `style.color` (black when it is not set), so one icon takes
any tint. The document is parsed in Eskiu, into straight lines and curves, only when its text
changes; the platform draws them.

What is drawn: `<path>` (all of the path syntax, arcs included), `<rect>` (with `rx`/`ry`),
`<circle>`, `<ellipse>`, `<line>`, `<polyline>` and `<polygon>`, inside `<svg>` and `<g>`;
`fill`, `stroke`, `stroke-width`, `opacity`, `fill-opacity`, `stroke-opacity`, `fill-rule`,
`stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit`, `display`, `visibility` and
`transform` (`matrix`, `translate`, `scale`, `rotate`, `skewX`, `skewY`), as attributes or in
a `style` attribute. Colors: `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`, `rgb()`, `rgba()`, the
basic names, `none` and `currentColor`.

Not drawn: gradients and patterns (a `url()` paint is its fallback color, else none), text,
`<use>`, clipping, masks and filters. `opacity` multiplies each shape's colors, so overlapping
shapes in a translucent group show through each other.

| Platform | Draws with |
|---|---|
| iOS | Core Graphics, in a view of its own |
| Android | the view's Canvas (`android.graphics.Path`) |
| Web | an `<svg>` element |

`svg_compile(svg, &out, &width, &height)` gives the display list itself (a `V` line with the
viewBox, then a paint line and a path line per shape), for tests or other renderers.

`examples/icons` shows tinted icons, a stroked star, arcs and transforms (`ui run ios`,
`ui run android` or `ui run web`).


## Install

In an app made with `ui new`:

```bash
eskiuc add svg --git https://github.com/eskiu-lang/ui-svg --rev v0.1.0
```
## Tests

`eskiuc test` compiles documents and checks the display lists: every path command, relative
and implicit ones, S and T reflections, arcs with packed flags, the shapes, inherited paint,
transforms, the style attribute, `url()` fallbacks, and the props `Svg` sends.

## License

MIT
