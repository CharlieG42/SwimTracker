// SettingsView.mc - v4
// Écran de réglage des paramètres de détection des virages.
// Permet d'ajuster les seuils sans recompiler l'application,
// pour itérer rapidement lors des tests en piscine.
//
// Navigation :
//   UP/DOWN   : se déplacer entre les 4 paramètres (mode navigation)
//   SET       : entrer en mode édition du paramètre sélectionné
//   UP/DOWN   : +/- la valeur (mode édition)
//   SET       : valider et revenir en mode navigation
//   BACK      : quitter l'écran réglages
// Compatible Connect IQ SDK 9.1.0

import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class SettingsView extends WatchUi.View {

    private var _model     as SwimModel;
    private var _selected  as Number  = 0;
    private var _editMode  as Boolean = false;

    private const PARAM_SWIM_THRESHOLD as Number = 0;
    private const PARAM_TURN_THRESHOLD as Number = 1;
    private const PARAM_MIN_SWIM_TIME  as Number = 2;
    private const PARAM_MIN_LAP_TIME   as Number = 3;
    private const PARAM_COUNT          as Number = 4;

    function initialize(model as SwimModel) {
        View.initialize();
        _model = model;
    }

    function onLayout(dc as Graphics.Dc) as Void {}
    function onShow() as Void {}

    function isEditMode() as Boolean {
        return _editMode;
    }

    function toggleEditMode() as Void {
        _editMode = !_editMode;
        WatchUi.requestUpdate();
    }

    function selectNext() as Void {
        if (_editMode) { return; }
        _selected = (_selected + 1) % PARAM_COUNT;
        WatchUi.requestUpdate();
    }

    function selectPrev() as Void {
        if (_editMode) { return; }
        _selected = (_selected - 1 + PARAM_COUNT) % PARAM_COUNT;
        WatchUi.requestUpdate();
    }

    function increaseSelected() as Void {
        if (!_editMode) { return; }
        if (_selected == PARAM_SWIM_THRESHOLD) {
            var v = _model.swimThreshold + SwimModel.SWIM_THRESHOLD_STEP;
            if (v > SwimModel.SWIM_THRESHOLD_MAX) { v = SwimModel.SWIM_THRESHOLD_MAX; }
            _model.setSwimThreshold(v);
        } else if (_selected == PARAM_TURN_THRESHOLD) {
            var v = _model.turnThreshold + SwimModel.TURN_THRESHOLD_STEP;
            if (v > SwimModel.TURN_THRESHOLD_MAX) { v = SwimModel.TURN_THRESHOLD_MAX; }
            _model.setTurnThreshold(v);
        } else if (_selected == PARAM_MIN_SWIM_TIME) {
            var v = _model.minSwimTimeMs + SwimModel.MIN_SWIM_TIME_STEP;
            if (v > SwimModel.MIN_SWIM_TIME_MAX) { v = SwimModel.MIN_SWIM_TIME_MAX; }
            _model.setMinSwimTimeMs(v);
        } else if (_selected == PARAM_MIN_LAP_TIME) {
            var v = _model.minLapTimeMs + SwimModel.MIN_LAP_TIME_STEP;
            if (v > SwimModel.MIN_LAP_TIME_MAX) { v = SwimModel.MIN_LAP_TIME_MAX; }
            _model.setMinLapTimeMs(v);
        }
        WatchUi.requestUpdate();
    }

    function decreaseSelected() as Void {
        if (!_editMode) { return; }
        if (_selected == PARAM_SWIM_THRESHOLD) {
            var v = _model.swimThreshold - SwimModel.SWIM_THRESHOLD_STEP;
            if (v < SwimModel.SWIM_THRESHOLD_MIN) { v = SwimModel.SWIM_THRESHOLD_MIN; }
            _model.setSwimThreshold(v);
        } else if (_selected == PARAM_TURN_THRESHOLD) {
            var v = _model.turnThreshold - SwimModel.TURN_THRESHOLD_STEP;
            if (v < SwimModel.TURN_THRESHOLD_MIN) { v = SwimModel.TURN_THRESHOLD_MIN; }
            _model.setTurnThreshold(v);
        } else if (_selected == PARAM_MIN_SWIM_TIME) {
            var v = _model.minSwimTimeMs - SwimModel.MIN_SWIM_TIME_STEP;
            if (v < SwimModel.MIN_SWIM_TIME_MIN) { v = SwimModel.MIN_SWIM_TIME_MIN; }
            _model.setMinSwimTimeMs(v);
        } else if (_selected == PARAM_MIN_LAP_TIME) {
            var v = _model.minLapTimeMs - SwimModel.MIN_LAP_TIME_STEP;
            if (v < SwimModel.MIN_LAP_TIME_MIN) { v = SwimModel.MIN_LAP_TIME_MIN; }
            _model.setMinLapTimeMs(v);
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 2, Graphics.FONT_SMALL,
                    "REGLAGES", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 22, w - 6, 22);

        _drawParamRow(dc, w, 26,  PARAM_SWIM_THRESHOLD,
                      "Seuil nage", _model.swimThreshold.format("%.1f") + "g");
        _drawParamRow(dc, w, 60,  PARAM_TURN_THRESHOLD,
                      "Seuil virage", _model.turnThreshold.format("%.1f") + "g");
        _drawParamRow(dc, w, 94,  PARAM_MIN_SWIM_TIME,
                      "Tps nage min", (_model.minSwimTimeMs / 1000.0).format("%.2f") + "s");
        _drawParamRow(dc, w, 128, PARAM_MIN_LAP_TIME,
                      "Tps entre long.", (_model.minLapTimeMs / 1000.0).format("%.2f") + "s");

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 158, w - 6, 158);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        if (_editMode) {
            dc.drawText(w / 2, 161, Graphics.FONT_XTINY,
                        "UP/DN:+/-  SET:valider",
                        Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(w / 2, 161, Graphics.FONT_XTINY,
                        "UP/DN:nav  SET:editer",
                        Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function _drawParamRow(dc as Graphics.Dc, w as Number, y as Number,
                                    paramIdx as Number, label as String,
                                    value as String) as Void {
        var isSelected = (paramIdx == _selected);
        var isEditingThis = isSelected && _editMode;

        if (isSelected) {
            if (isEditingThis) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            }
            dc.fillRectangle(4, y - 2, w - 8, 32);
        }

        if (isEditingThis) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(10, y, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT);

        if (isEditingThis) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(w - 10, y + 10, Graphics.FONT_NUMBER_MILD,
                    value, Graphics.TEXT_JUSTIFY_RIGHT);
    }
}

// Delegate Réglages
class SettingsDelegate extends WatchUi.BehaviorDelegate {

    private var _model as SwimModel;
    private var _view  as SettingsView;

    function initialize(model as SwimModel, view as SettingsView) {
        BehaviorDelegate.initialize();
        _model = model;
        _view  = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            if (_view.isEditMode()) {
                _view.increaseSelected();
            } else {
                _view.selectPrev();
            }
            return true;
        }

        if (key == WatchUi.KEY_DOWN) {
            if (_view.isEditMode()) {
                _view.decreaseSelected();
            } else {
                _view.selectNext();
            }
            return true;
        }

        if (key == WatchUi.KEY_ESC || key == WatchUi.KEY_ENTER) {
            _view.toggleEditMode();
            return true;
        }

        return false;
    }

    function onBack() as Boolean {
        if (_view.isEditMode()) {
            _view.toggleEditMode();
            return true;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}