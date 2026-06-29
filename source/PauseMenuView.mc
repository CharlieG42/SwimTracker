// PauseMenuView.mc - v4
// Menu de pause utilisant le Menu2 natif Garmin
// Compatible Connect IQ SDK 9.1.0

import Toybox.WatchUi;
import Toybox.Lang;

class PauseMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "PAUSE"});
        addItem(new WatchUi.MenuItem("Reprendre",       null, :resume,  null));
        addItem(new WatchUi.MenuItem("Sauvegarder",     null, :save,    null));
        addItem(new WatchUi.MenuItem("Voir resume",     null, :summary, null));
        addItem(new WatchUi.MenuItem("Quitter",         null, :discard, null));
    }
}

class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as SwimModel;

    function initialize(model as SwimModel) {
        Menu2InputDelegate.initialize();
        _model = model;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :resume) {
            _model.resumeActivity();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);

        } else if (id == :save) {
            _model.finishActivity();
            // Fermer le menu Menu2 d'abord, puis afficher le résumé
            // switchToView depuis un Menu2InputDelegate peut laisser le menu
            // affiché par-dessus — on utilise popView + pushView à la place
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new SummaryMenu(_model),
                             new SummaryDelegate(_model),
                             WatchUi.SLIDE_LEFT);

        } else if (id == :summary) {
            WatchUi.pushView(new SummaryMenu(_model),
                             new SummaryDelegate(_model),
                             WatchUi.SLIDE_LEFT);

        } else if (id == :discard) {
            _model.discardActivity();
            _model.resetActivity();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }

    function onBack() as Void {
        // BACK dans le menu → reprendre
        _model.resumeActivity();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
