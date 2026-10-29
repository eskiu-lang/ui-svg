// <svg> on Android: a view that draws the display list (src/svg.esk) on its Canvas, the
// viewBox scaled to fit its bounds and centered.
package org.eskiu.svg;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.view.View;
import java.util.ArrayList;
import org.eskiu.ui.UiActivity;

public class SvgView extends View {
    private static final class Shape {
        final Path path = new Path();
        String fill, stroke;
        float width = 1, miter = 4;
        int cap, join;
    }

    private float boxX, boxY, boxWidth, boxHeight;
    private final ArrayList<Shape> shapes = new ArrayList<>();
    private int color = 0x000000ff;
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);

    public static void setup() {
        UiActivity.registerView("svg", new UiActivity.ViewFactory() {
            @Override public View create(Context context, UiActivity.ViewEvents events) { return new SvgView(context); }
            @Override public void set(View view, String name, String value) {
                SvgView svg = (SvgView)view;
                if (name.equals("drawing")) svg.setDrawing(value);
                else if (name.equals("color")) {
                    svg.color = (int)Long.parseLong(value.isEmpty() ? "000000ff" : value, 16);
                    svg.invalidate();
                }
            }
        });
    }

    SvgView(Context context) { super(context); }

    private static void readPath(Path path, String text) {
        String[] tokens = text.trim().split(" +");
        int at = 0;
        float[] v = new float[6];
        while (at < tokens.length) {
            String token = tokens[at++];
            if (token.isEmpty()) continue;
            char command = token.charAt(0);
            int n = command == 'C' ? 6 : command == 'Q' ? 4 : command == 'Z' ? 0 : 2;
            // The first number is joined to its command ("M2"), the rest stand alone.
            for (int i = 0; i < n; i++) {
                String number = i == 0 ? token.substring(1) : (at < tokens.length ? tokens[at++] : "0");
                try { v[i] = Float.parseFloat(number); } catch (NumberFormatException e) { return; }
            }
            if (command == 'M') path.moveTo(v[0], v[1]);
            else if (command == 'L') path.lineTo(v[0], v[1]);
            else if (command == 'C') path.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]);
            else if (command == 'Q') path.quadTo(v[0], v[1], v[2], v[3]);
            else if (command == 'Z') path.close();
            else return;
        }
    }

    void setDrawing(String drawing) {
        shapes.clear();
        boxWidth = 0; boxHeight = 0;
        String[] lines = drawing.split("\n");
        if (lines.length > 0 && lines[0].startsWith("V ")) {
            String[] box = lines[0].split(" ");
            if (box.length == 5) {
                boxX = Float.parseFloat(box[1]); boxY = Float.parseFloat(box[2]);
                boxWidth = Float.parseFloat(box[3]); boxHeight = Float.parseFloat(box[4]);
            }
        }
        for (int i = 1; i + 1 < lines.length; i += 2) {
            String[] p = lines[i].split(" ");
            if (p.length != 8 || !p[0].equals("S")) continue;
            Shape shape = new Shape();
            shape.fill = p[1]; shape.stroke = p[2];
            shape.width = Float.parseFloat(p[3]);
            shape.path.setFillType(p[4].equals("1") ? Path.FillType.EVEN_ODD : Path.FillType.WINDING);
            shape.cap = Integer.parseInt(p[5]); shape.join = Integer.parseInt(p[6]);
            shape.miter = Float.parseFloat(p[7]);
            readPath(shape.path, lines[i + 1]);
            shapes.add(shape);
        }
        invalidate();
    }

    // A paint token as an ARGB color: "cAA" is the color at alpha AA, else RRGGBBAA.
    private int argb(String token) {
        long rgba;
        if (token.charAt(0) == 'c') {
            int alpha = ((color & 255) * Integer.parseInt(token.substring(1), 16) + 127) / 255;
            rgba = ((long)color & 0xffffff00L) | alpha;
        } else rgba = Long.parseLong(token, 16);
        return (int)(((rgba & 0xff) << 24) | (rgba >>> 8));
    }

    @Override protected void onDraw(Canvas canvas) {
        if (boxWidth <= 0 || boxHeight <= 0) return;
        float scale = Math.min(getWidth() / boxWidth, getHeight() / boxHeight);
        canvas.save();
        canvas.translate((getWidth() - boxWidth * scale) / 2, (getHeight() - boxHeight * scale) / 2);
        canvas.scale(scale, scale);
        canvas.translate(-boxX, -boxY);
        Paint.Cap[] caps = {Paint.Cap.BUTT, Paint.Cap.ROUND, Paint.Cap.SQUARE};
        Paint.Join[] joins = {Paint.Join.MITER, Paint.Join.ROUND, Paint.Join.BEVEL};
        for (Shape shape : shapes) {
            if (!shape.fill.equals("-")) {
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(argb(shape.fill));
                canvas.drawPath(shape.path, paint);
            }
            if (!shape.stroke.equals("-")) {
                paint.setStyle(Paint.Style.STROKE);
                paint.setColor(argb(shape.stroke));
                paint.setStrokeWidth(shape.width);
                paint.setStrokeCap(caps[Math.max(0, Math.min(2, shape.cap))]);
                paint.setStrokeJoin(joins[Math.max(0, Math.min(2, shape.join))]);
                paint.setStrokeMiter(shape.miter);
                canvas.drawPath(shape.path, paint);
            }
        }
        canvas.restore();
    }
}
