// PoolSetupView.mc - v4
// Boutons sur écran PISCINE (activité non lancée) :
//   UP   (milieu-gauche) → ouvrir Réglages détection
//   DOWN (bas-gauche)    → diminuer longueur piscine
//   SET  (bas-droit)     → valider et passer à l'écran activité
//   onNextPage/PrevPage  → augmenter/diminuer (geste scroll ou bouton système)
// Compatible Connect IQ SDK 9.1.0

import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

class PoolSetupView extends WatchUi.View {

    private var _model as SwimModel;

    function initialize(model as SwimModel) {
        View.initialize();
        _model = model;
    }

    function onLayout(dc as Graphics.Dc) as Void {}
    function onShow() as Void {}

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 8, Graphics.FONT_SMALL,
                    "PISCINE", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(12, 30, w - 12, 30);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 34, Graphics.FONT_XTINY,
                    "LONGUEUR (m)", Graphics.TEXT_JUSTIFY_CENTER);

        _drawArrowUp(dc, w / 2, 58);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 64, Graphics.FONT_NUMBER_HOT,
                    _model.getPoolLength().toString(),
                    Graphics.TEXT_JUSTIFY_CENTER);

        _drawArrowDown(dc, w / 2, 122);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(12, 136, w - 12, 136);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 140, Graphics.FONT_XTINY,
                    "SET: valider",
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, 153, Graphics.FONT_XTINY,
                    "DN: changer",
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 164, Graphics.FONT_XTINY,
                    "UP: reglages",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function _drawArrowUp(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx, cy - 10], [cx - 12, cy + 4], [cx + 12, cy + 4]]);
    }

    private function _drawArrowDown(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx, cy + 10], [cx - 12, cy - 4], [cx + 12, cy - 4]]);
    }

    private function _drawPositionDots(dc as Graphics.Dc, w as Number, y as Number) as Void {
        var count   = SwimModel.POOL_LENGTHS.size();
        var spacing = 18;
        var startX  = w / 2 - (count * spacing) / 2 + spacing / 2;
        for (var i = 0; i < count; i++) {
            var cx = startX + i * spacing;
            if (i == _model.poolLengthIdx) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, y, 4);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, y, 3);
            }
        }
    }
}

// ── Delegate Setup ────────────────────────────────────────────────────────────

class PoolSetupDelegate extends WatchUi.BehaviorDelegate {

    private var _model as SwimModel;

    function initialize(model as SwimModel) {
        BehaviorDelegate.initialize();
        _model = model;
    }

    function onNextPage() as Boolean {
        _model.increasePoolLength();
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        _model.decreasePoolLength();
        WatchUi.requestUpdate();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        // SET/BACK (bas-droit) → valider longueur et passer à l'activité
        if (key == WatchUi.KEY_ESC || key == WatchUi.KEY_ENTER) {
            _model.state = SwimModel.STATE_READY;
            WatchUi.pushView(new SwimView(_model),
                             new SwimDelegate(_model),
                             WatchUi.SLIDE_LEFT);
            return true;
        }

        // MENU/UP (milieu-gauche) → ouvrir l'écran Réglages détection
        if (key == WatchUi.KEY_UP) {
            var settingsView = new SettingsView(_model);
            WatchUi.pushView(settingsView,
                             new SettingsDelegate(_model, settingsView),
                             WatchUi.SLIDE_LEFT);
            return true;
        }

        // ABC/DOWN (bas-gauche) → diminuer la longueur de piscine
        if (key == WatchUi.KEY_DOWN) {
            _model.decreasePoolLength();
            WatchUi.requestUpdate();
            return true;
        }

        return false;
    }

    function onBack() as Boolean {
        System.exit();
        return true;
    }
}
