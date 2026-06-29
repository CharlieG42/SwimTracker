// SwimView.mc - v4 mise en page corrigée
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.System;

class SwimView extends WatchUi.View {

    private var _model as SwimModel;
    private var _timer as Timer.Timer;
    private var _blink as Boolean = false;

    function initialize(model as SwimModel) {
        View.initialize();
        _model = model;
        _timer = new Timer.Timer();
    }

    function onLayout(dc as Graphics.Dc) as Void {}

    function onShow() as Void {
        _timer.start(method(:onTimer), 1000, true);
    }

    function onHide() as Void {
        _timer.stop();
    }

    function onTimer() as Void {
        _blink = !_blink;
        _model.updateElapsedTime();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w     = dc.getWidth();   // 176
        var h     = dc.getHeight();  // 176
        var state = _model.state;
        var cx    = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Ligne 1 : titre + taille piscine + état ──────────────────────────
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(8, 2, Graphics.FONT_XTINY,
                    "NATATION", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(w - 8, 2, Graphics.FONT_XTINY,
                    _model.getPoolLength().toString() + "m",
                    Graphics.TEXT_JUSTIFY_RIGHT);

        // ── Ligne 2 : indicateur état (centré, sous le titre) ────────────────
        _drawStateIndicator(dc, w, 16, state);

        // ── Séparateur ────────────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(8, 30, w - 8, 30);

        // ── DURÉE ─────────────────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 33, Graphics.FONT_XTINY,
                    "DUREE", Graphics.TEXT_JUSTIFY_CENTER);

        var showDuration = !(state == SwimModel.STATE_PAUSED && _blink);
        if (showDuration) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 43, Graphics.FONT_NUMBER_MEDIUM,
                        _model.getFormattedDuration(),
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

        // ── Séparateur ────────────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(8, 88, w - 8, 88);

        // ── LONGUEURS (gauche) | ALLURE (droite) ─────────────────────────────
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, 88, cx, 134);

        // Longueurs
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx / 2, 91, Graphics.FONT_XTINY,
                    "LONG.", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx / 2, 101, Graphics.FONT_NUMBER_MEDIUM,
                    _model.lapCount.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Allure
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + cx / 2, 91, Graphics.FONT_XTINY,
                    "ALLURE", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + cx / 2, 104, Graphics.FONT_SMALL,
                    _model.getFormattedPace(),
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + cx / 2, 124, Graphics.FONT_XTINY,
                    "/100m", Graphics.TEXT_JUSTIFY_CENTER);

        // ── Séparateur ────────────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(8, 134, w - 8, 134);

        // ── DISTANCE (gauche) | MOUVEMENTS (droite) ──────────────────────────
        dc.drawLine(cx, 134, cx, 158);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx / 2, 137, Graphics.FONT_XTINY,
                    "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx / 2, 147, Graphics.FONT_SMALL,
                    _model.getFormattedDistance(),
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Mouvements : deux valeurs (pics détectés / estimation temporelle)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + cx / 2, 137, Graphics.FONT_XTINY,
                    "MVTS", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + cx / 2, 147, Graphics.FONT_SMALL,
                    _model.strokeCountPeaks.format("%d") + "/" + _model.strokeCountEstimate.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER);

        // ── Séparateur bas ────────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(8, 158, w - 8, 158);

        // ── Aide boutons ──────────────────────────────────────────────────────
        _drawButtonHints(dc, w, state);
    }

    private function _drawStateIndicator(dc as Graphics.Dc, w as Number,
                                          y as Number, state) as Void {
        var label = "";
        var color = Graphics.COLOR_WHITE;

        if (state == SwimModel.STATE_READY) {
            label = "PRET";
            color = Graphics.COLOR_LT_GRAY;
        } else if (state == SwimModel.STATE_ACTIVE) {
            label = "● ACTIF";
            color = Graphics.COLOR_WHITE;
        } else if (state == SwimModel.STATE_PAUSED) {
            label = "PAUSE";
            color = Graphics.COLOR_LT_GRAY;
        } else if (state == SwimModel.STATE_FINISHED) {
            label = "TERMINE";
            color = Graphics.COLOR_LT_GRAY;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, y, Graphics.FONT_XTINY,
                    label, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function _drawButtonHints(dc as Graphics.Dc, w as Number, state) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);

        if (state == SwimModel.STATE_READY) {
            dc.drawText(8, 161, Graphics.FONT_XTINY,
                        "UP:reglages",
                        Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(w - 8, 161, Graphics.FONT_XTINY,
                        "SET:start",
                        Graphics.TEXT_JUSTIFY_RIGHT);

        } else if (state == SwimModel.STATE_ACTIVE) {
            dc.drawText(8, 161, Graphics.FONT_XTINY,
                        "ABC:+long",
                        Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(w - 8, 161, Graphics.FONT_XTINY,
                        "SET:menu",
                        Graphics.TEXT_JUSTIFY_RIGHT);

        } else if (state == SwimModel.STATE_PAUSED) {
            dc.drawText(w / 2, 161, Graphics.FONT_XTINY,
                        "SET: menu pause",
                        Graphics.TEXT_JUSTIFY_CENTER);

        } else if (state == SwimModel.STATE_FINISHED) {
            dc.drawText(w / 2, 161, Graphics.FONT_XTINY,
                        "SET: nouvelle session",
                        Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class SwimDelegate extends WatchUi.BehaviorDelegate {

    private var _model as SwimModel;

    function initialize(model as SwimModel) {
        BehaviorDelegate.initialize();
        _model = model;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key   = keyEvent.getKey();
        var state = _model.state;

        if (key == WatchUi.KEY_ESC || key == WatchUi.KEY_ENTER) {

            if (state == SwimModel.STATE_READY) {
                _model.startActivity();
                return true;
            }

            if (state == SwimModel.STATE_ACTIVE) {
                _model.pauseActivity();
                WatchUi.pushView(new PauseMenu(),
                                 new PauseMenuDelegate(_model),
                                 WatchUi.SLIDE_UP);
                return true;
            }

            if (state == SwimModel.STATE_PAUSED) {
                WatchUi.pushView(new PauseMenu(),
                                 new PauseMenuDelegate(_model),
                                 WatchUi.SLIDE_UP);
                return true;
            }

            if (state == SwimModel.STATE_FINISHED) {
                _model.resetActivity();
                System.exit();
                return true;
            }
        }

        if (key == WatchUi.KEY_DOWN && state == SwimModel.STATE_ACTIVE) {
            _model.addLapManual();
            return true;
        }

        // MENU/UP (milieu-gauche) — comportement contextuel :
        //   STATE_READY  → ouvrir l'écran Réglages (seuils de détection)
        //   STATE_ACTIVE / STATE_PAUSED → ouvrir l'écran Debug capteur
        if (key == WatchUi.KEY_UP) {
            if (state == SwimModel.STATE_READY) {
                var settingsView = new SettingsView(_model);
                WatchUi.pushView(settingsView,
                                 new SettingsDelegate(_model, settingsView),
                                 WatchUi.SLIDE_LEFT);
                return true;
            }
            if (state == SwimModel.STATE_ACTIVE || state == SwimModel.STATE_PAUSED) {
                WatchUi.pushView(new DebugView(_model),
                                 new DebugDelegate(),
                                 WatchUi.SLIDE_LEFT);
                return true;
            }
        }

        return false;
    }

    function onBack() as Boolean {
        var state = _model.state;
        if (state == SwimModel.STATE_ACTIVE) {
            return true;
        }
        if (state == SwimModel.STATE_READY) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false;
    }
}
