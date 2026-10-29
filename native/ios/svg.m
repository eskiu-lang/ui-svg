// <svg> on iOS: a view that draws the display list (src/svg.esk) with Core Graphics, the
// viewBox scaled to fit its bounds and centered.
#import "ui_native.h"

@interface EskiuSvgShape : NSObject
@property(nonatomic) CGPathRef path;
@property(nonatomic) uint32_t fill, stroke;
@property(nonatomic) BOOL fillCurrent, strokeCurrent, hasFill, hasStroke, evenOdd;
@property(nonatomic) CGFloat width, miter;
@property(nonatomic) int cap, join;
@end
@implementation EskiuSvgShape
- (void)dealloc { CGPathRelease(_path); }
@end

@interface EskiuSvgView : UIView
@property(nonatomic) CGRect box;
@property(nonatomic, strong) NSArray<EskiuSvgShape *> *shapes;
@property(nonatomic) uint32_t color;
@end

// A paint token: "-" none, "cAA" currentColor at alpha AA, else RRGGBBAA.
static void readPaint(const char *token, BOOL *has, BOOL *current, uint32_t *rgba) {
    *has = token[0] != '-';
    *current = token[0] == 'c';
    *rgba = (uint32_t)strtoul(*current ? token + 1 : token, NULL, 16);
}

static UIColor *rgbaColor(uint32_t v) {
    return [UIColor colorWithRed:(v >> 24) / 255.0 green:((v >> 16) & 255) / 255.0 blue:((v >> 8) & 255) / 255.0
                           alpha:(v & 255) / 255.0];
}

static CGPathRef readPath(const char *text) {
    CGMutablePathRef path = CGPathCreateMutable();
    const char *at = text;
    char *end;
    double v[6];
    while (*at) {
        while (*at == ' ') at++;
        char command = *at;
        if (!command) break;
        at++;
        int n = command == 'C' ? 6 : command == 'Q' ? 4 : command == 'Z' ? 0 : 2;
        for (int i = 0; i < n; i++) { v[i] = strtod(at, &end); at = end; }
        if (command == 'M') CGPathMoveToPoint(path, NULL, v[0], v[1]);
        else if (command == 'L') CGPathAddLineToPoint(path, NULL, v[0], v[1]);
        else if (command == 'C') CGPathAddCurveToPoint(path, NULL, v[0], v[1], v[2], v[3], v[4], v[5]);
        else if (command == 'Q') CGPathAddQuadCurveToPoint(path, NULL, v[0], v[1], v[2], v[3]);
        else if (command == 'Z') CGPathCloseSubpath(path);
        else break;
    }
    return path;
}

@implementation EskiuSvgView
- (void)setDrawing:(NSString *)drawing {
    NSArray<NSString *> *lines = [drawing componentsSeparatedByString:@"\n"];
    NSMutableArray *shapes = [NSMutableArray new];
    self.box = CGRectZero;
    if (lines.count > 0 && [lines[0] hasPrefix:@"V "]) {
        double x = 0, y = 0, w = 0, h = 0;
        sscanf(lines[0].UTF8String, "V %lf %lf %lf %lf", &x, &y, &w, &h);
        self.box = CGRectMake(x, y, w, h);
    }
    for (NSUInteger i = 1; i + 1 < lines.count; i += 2) {
        char fill[16] = "", stroke[16] = "";
        double width = 1, miter = 4;
        int evenOdd = 0, cap = 0, join = 0;
        if (sscanf(lines[i].UTF8String, "S %15s %15s %lf %d %d %d %lf", fill, stroke, &width, &evenOdd, &cap, &join, &miter) != 7) continue;
        EskiuSvgShape *shape = [EskiuSvgShape new];
        BOOL has, current; uint32_t rgba;
        readPaint(fill, &has, &current, &rgba);
        shape.hasFill = has; shape.fillCurrent = current; shape.fill = rgba;
        readPaint(stroke, &has, &current, &rgba);
        shape.hasStroke = has; shape.strokeCurrent = current; shape.stroke = rgba;
        shape.width = width; shape.miter = miter; shape.evenOdd = evenOdd; shape.cap = cap; shape.join = join;
        shape.path = readPath(lines[i + 1].UTF8String);
        [shapes addObject:shape];
    }
    self.shapes = shapes;
    [self setNeedsDisplay];
}

- (UIColor *)paint:(uint32_t)rgba current:(BOOL)current {
    if (!current) return rgbaColor(rgba);
    uint32_t alpha = ((self.color & 255) * (rgba & 255) + 127) / 255;
    return rgbaColor((self.color & 0xffffff00) | alpha);
}

- (void)drawRect:(CGRect)rect {
    if (self.box.size.width <= 0 || self.box.size.height <= 0) return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGSize size = self.bounds.size;
    CGFloat scale = MIN(size.width / self.box.size.width, size.height / self.box.size.height);
    CGContextTranslateCTM(context, (size.width - self.box.size.width * scale) / 2, (size.height - self.box.size.height * scale) / 2);
    CGContextScaleCTM(context, scale, scale);
    CGContextTranslateCTM(context, -self.box.origin.x, -self.box.origin.y);
    const CGLineCap caps[] = {kCGLineCapButt, kCGLineCapRound, kCGLineCapSquare};
    const CGLineJoin joins[] = {kCGLineJoinMiter, kCGLineJoinRound, kCGLineJoinBevel};
    for (EskiuSvgShape *shape in self.shapes) {
        if (shape.hasFill) {
            CGContextAddPath(context, shape.path);
            [[self paint:shape.fill current:shape.fillCurrent] setFill];
            CGContextDrawPath(context, shape.evenOdd ? kCGPathEOFill : kCGPathFill);
        }
        if (shape.hasStroke) {
            CGContextAddPath(context, shape.path);
            [[self paint:shape.stroke current:shape.strokeCurrent] setStroke];
            CGContextSetLineWidth(context, shape.width);
            CGContextSetLineCap(context, caps[MIN(2, MAX(0, shape.cap))]);
            CGContextSetLineJoin(context, joins[MIN(2, MAX(0, shape.join))]);
            CGContextSetMiterLimit(context, shape.miter);
            CGContextStrokePath(context);
        }
    }
}
@end

UI_NATIVE_SETUP(svg) {
    ui_register_view(@"svg", ^UIView *(UiViewEmit emit) {
        EskiuSvgView *view = [EskiuSvgView new];
        view.opaque = NO;
        view.backgroundColor = UIColor.clearColor;
        view.contentMode = UIViewContentModeRedraw;
        view.color = 0x000000ff;
        return view;
    }, ^(UIView *view, NSString *name, NSString *value) {
        EskiuSvgView *svg = (EskiuSvgView *)view;
        if ([name isEqualToString:@"drawing"]) [svg setDrawing:value];
        else if ([name isEqualToString:@"color"]) {
            svg.color = (uint32_t)strtoul(value.UTF8String, NULL, 16);
            [svg setNeedsDisplay];
        }
    });
}
