// DebugView.mc - v4
// Écran de calibration : affiche les valeurs brutes du capteur en temps réel
// pour permettre de calibrer le seuil de détection des virages.
// Compatible Connect IQ SDK 9.1.0

import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;

class DebugView extends WatchUi.View {

    private var _model as SwimModel;
    private var _timer as Timer.Timer;

    function initialize(model as SwimModel) {
        View.initialize();
        _model = model;
        _timer = new Timer.Timer();
    }

    function onLayout(dc as Graphics.Dc) as Void {}

    function onShow() as Void {
        // Rafraîchissement rapide pour voir les valeurs évoluer en direct
        _timer.start(method(:onTimer), 250, true);
    }

    function onHide() as Void {
        _timer.stop();
    }

    function onTimer() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 1, Graphics.FONT_XTINY,
                    "DEBUG CAPTEUR", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 14, w - 6, 14);

        // Amplitudes par axe (g) — 3 lignes compactes
        _drawRow(dc, w, 17,  "X", _model.debugAmpX);
        _drawRow(dc, w, 34,  "Y", _model.debugAmpY);
        _drawRow(dc, w, 51,  "Z", _model.debugAmpZ);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 70, w - 6, 70);

        // Max retenu / fast / baseline / ratio
        _drawRow(dc, w, 73,  "MAX",  _model.debugAmpMax);
        _drawRow(dc, w, 90,  "FAST", _model.debugFastAccel);
        _drawRow(dc, w, 107, "BASE", _model.debugBaseline);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, 124, Graphics.FONT_XTINY,
                    "RATIO", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(w - 10, 124, Graphics.FONT_SMALL,
                    _model.debugRatio.format("%.2f"), Graphics.TEXT_JUSTIFY_RIGHT);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 144, w - 6, 144);

        // Min/Max observés depuis le début — utiles pour calibrer le seuil
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 147, Graphics.FONT_XTINY,
                    "Min:" + _model.debugMinAmpEver.format("%.2f")
                    + " Max:" + _model.debugMaxAmpEver.format("%.2f"),
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 161, Graphics.FONT_XTINY,
                    "BCK: retour",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function _drawRow(dc as Graphics.Dc, w as Number, y as Number,
                               label as String, value as Float) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, y, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 10, y, Graphics.FONT_SMALL,
                    value.format("%.2f"), Graphics.TEXT_JUSTIFY_RIGHT);
    }
}

// ── Delegate Debug ─────────────────────────────────────────────────────────────

class DebugDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
