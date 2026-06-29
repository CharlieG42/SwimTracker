import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SwimTrackerApp extends Application.AppBase {

    private var _swimModel as SwimModel;

    function initialize() {
        AppBase.initialize();
        _swimModel = new SwimModel();
    }

    function getInitialView() {
        var view = new PoolSetupView(_swimModel);
        var delegate = new PoolSetupDelegate(_swimModel);
        return [view, delegate];
    }

    function onStop(state as Dictionary?) as Void {
        _swimModel.onStop();
    }
}

function getApp() as SwimTrackerApp {
    return Application.getApp() as SwimTrackerApp;
}
