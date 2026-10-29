// <svg> on the web: the "svg" view, an <svg> element built from the display list
// (src/svg.esk), whose path data is already SVG's.
const ns = 'http://www.w3.org/2000/svg';

// A paint token as CSS: "-" none, "cAA" the current color at alpha AA, else RRGGBBAA.
function css(token, color) {
  if (token === '-') return 'none';
  const rgba = token[0] === 'c'
    ? ((color & 0xffffff00) | Math.round(((color & 255) * parseInt(token.slice(1), 16)) / 255)) >>> 0
    : parseInt(token, 16) >>> 0;
  return `rgba(${rgba >>> 24}, ${(rgba >>> 16) & 255}, ${(rgba >>> 8) & 255}, ${(rgba & 255) / 255})`;
}

export function setup(ui) {
  ui.registerView('svg', {
    create() {
      const svg = document.createElementNS(ns, 'svg');
      svg.setAttribute('width', '100%');
      svg.setAttribute('height', '100%');
      svg.style.display = 'block';
      let drawing = '';
      let color = 0x000000ff;
      const draw = () => {
        while (svg.firstChild) svg.firstChild.remove();
        const lines = drawing.split('\n');
        if (!lines[0].startsWith('V ')) return;
        svg.setAttribute('viewBox', lines[0].slice(2));
        const caps = ['butt', 'round', 'square'];
        const joins = ['miter', 'round', 'bevel'];
        for (let i = 1; i + 1 < lines.length; i += 2) {
          const [tag, fill, stroke, width, rule, cap, join, miter] = lines[i].split(' ');
          if (tag !== 'S') continue;
          const path = document.createElementNS(ns, 'path');
          path.setAttribute('d', lines[i + 1]);
          path.setAttribute('fill', css(fill, color));
          path.setAttribute('stroke', css(stroke, color));
          path.setAttribute('stroke-width', width);
          path.setAttribute('fill-rule', rule === '1' ? 'evenodd' : 'nonzero');
          path.setAttribute('stroke-linecap', caps[Number(cap)] || 'butt');
          path.setAttribute('stroke-linejoin', joins[Number(join)] || 'miter');
          path.setAttribute('stroke-miterlimit', miter);
          svg.appendChild(path);
        }
      };
      return {
        element: svg,
        set(name, value) {
          if (name === 'drawing') drawing = value;
          else if (name === 'color') color = parseInt(value || '000000ff', 16) >>> 0;
          draw();
        },
      };
    },
  });
}
