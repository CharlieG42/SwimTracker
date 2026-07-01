// DebugView.mc - v5
// Écran de calibration : affiche les valeurs brutes du capteur en temps réel
// pour permettre de calibrer les seuils de détection des virages.
// Inclut maintenant les données gyroscope pour la fusion accéléromètre/gyro.
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

        // Titre
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 1, Graphics.FONT_XTINY,
                    "DEBUG CAPTEURS", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 14, w - 6, 14);

        // Section Accéléromètre
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, 17, Graphics.FONT_XTINY, "ACCEL", Graphics.TEXT_JUSTIFY_LEFT);

        _drawRow(dc, w, 28,  "X", _model.debugAmpX);
        _drawRow(dc, w, 41,  "Y", _model.debugAmpY);
        _drawRow(dc, w, 54,  "Z", _model.debugAmpZ);
        _drawRow(dc, w, 67,  "MAX", _model.debugAmpMax);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 78, w - 6, 78);

        // Section Gyroscope
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, 81, Graphics.FONT_XTINY, "GYRO", Graphics.TEXT_JUSTIFY_LEFT);

        _drawRow(dc, w, 92,  "GX", _model.debugGyroX);
        _drawRow(dc, w, 105, "GY", _model.debugGyroY);
        _drawRow(dc, w, 118, "GZ", _model.debugGyroZ);
        _drawRow(dc, w, 131, "MAG", _model.debugGyroMag);
        _drawRow(dc, w, 144, "SMOOTH", _model.debugSmoothedGyro);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 155, w - 6, 155);

        // Section Calculés (accel)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, 158, Graphics.FONT_XTINY, "CALC", Graphics.TEXT_JUSTIFY_LEFT);

        _drawRow(dc, w, 169, "FAST", _model.debugFastAccel);
        _drawRow(dc, w, 182, "BASE", _model.debugBaseline);
        dc.drawText(10, 195, Graphics.FONT_XTINY, "RATIO", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(w - 10, 195, Graphics.FONT_SMALL,
                    _model.debugRatio.format("%.2f"), Graphics.TEXT_JUSTIFY_RIGHT);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 206, w - 6, 206);

        // Min/Max observés
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 209, Graphics.FONT_XTINY,
                    "Amp Min:" + _model.debugMinAmpEver.format("%.2f")
                    + " Max:" + _model.debugMaxAmpEver.format("%.2f"),
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 223, Graphics.FONT_XTINY,
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

// Delegate Debug
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