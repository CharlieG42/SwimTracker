// SummaryView.mc - v4
// Résumé sous forme de menu déroulant natif Garmin Menu2
// Compatible Connect IQ SDK 9.1.0

import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class SummaryMenu extends WatchUi.Menu2 {

    function initialize(model as SwimModel) {
        Menu2.initialize({:title => "RESUME"});

        addItem(new WatchUi.MenuItem(
            "Duree",
            model.getFormattedDuration(),
            :duree,
            null
        ));
        addItem(new WatchUi.MenuItem(
            "Distance",
            model.getFormattedDistance(),
            :distance,
            null
        ));
        addItem(new WatchUi.MenuItem(
            "Longueurs",
            model.lapCount.format("%d"),
            :longueurs,
            null
        ));
        addItem(new WatchUi.MenuItem(
            "Allure",
            model.getFormattedPace() + "/100m",
            :allure,
            null
        ));
        addItem(new WatchUi.MenuItem(
            "Mouvements",
            model.strokeCountPeaks.format("%d") + " / " + model.strokeCountEstimate.format("%d"),
            :mouvements,
            null
        ));
        addItem(new WatchUi.MenuItem(
            "Piscine",
            model.getPoolLength().toString() + " m",
            :piscine,
            null
        ));

        // Dernière ligne = action de sortie, son libellé dépend du contexte
        if (model.state == SwimModel.STATE_FINISHED) {
            addItem(new WatchUi.MenuItem(
                "Quitter",
                "appli",
                :exit,
                null
            ));
        } else {
            addItem(new WatchUi.MenuItem(
                "Retour",
                "pause",
                :back,
                null
            ));
        }
    }
}

// ── Delegate Résumé ───────────────────────────────────────────────────────────

class SummaryDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as SwimModel;

    function initialize(model as SwimModel) {
        Menu2InputDelegate.initialize();
        _model = model;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        // Seules les entrées Quitter / Retour déclenchent une action
        if (id == :exit) {
            _model.resetActivity();
            System.exit();
        } else if (id == :back) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        // Les autres entrées sont purement informatives : pas d'action
    }

    function onBack() as Void {
        _exitSummary();
    }

    private function _exitSummary() as Void {
        if (_model.state == SwimModel.STATE_FINISHED) {
            _model.resetActivity();
            System.exit();
        } else {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
